#!/usr/bin/env bash
# lima-sandbox-runner.sh — Hardened PoC staging + unprivileged nerdctl execution in Lima ga-proof VM
set -euo pipefail

RUN_DIR=""
POC_ID="poc-default"
SCRIPT=""
AUTO_EXEC=false
START_VM=false
CPU="1"
MEMORY="512m"
PIDS="64"
WALL="60"
VM_NAME="ga-proof"
# Pinned by digest so a re-pull cannot swap the base image under a staged PoC (M1).
# Override with SECAUDIT_IMAGE for other architectures; the VM image store must contain it.
IMAGE="${SECAUDIT_IMAGE:-alpine@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b}"
VM_BASE=""
STAGE_TAR=""
OUT_FILE=""
ERR_FILE=""
declare -a STAGE_FILES=()
declare -a ALLOWLIST_PROMOTE=()

# macOS has no `timeout` binary; wrap host-side lima calls only when available (M1).
if command -v timeout >/dev/null 2>&1; then
  TIMEOUT_BIN="timeout"
elif command -v gtimeout >/dev/null 2>&1; then
  TIMEOUT_BIN="gtimeout"
else
  TIMEOUT_BIN=""
fi

# run_with_timeout <seconds> <cmd...> — no-op wrapper when no timeout binary exists.
run_with_timeout() {
  local secs="$1"
  shift
  if [[ -n "$TIMEOUT_BIN" ]]; then
    "$TIMEOUT_BIN" "$secs" "$@"
  else
    "$@"
  fi
}

cleanup() {
  if [[ -n "${VM_BASE:-}" ]]; then
    lima --instance "$VM_NAME" rm -rf "$VM_BASE" 2>/dev/null || true
  fi
  if [[ -n "${STAGE_TAR:-}" && -f "$STAGE_TAR" ]]; then
    rm -f "$STAGE_TAR" 2>/dev/null || true
  fi
  if [[ -n "${OUT_FILE:-}" && -f "$OUT_FILE" ]]; then
    rm -f "$OUT_FILE" 2>/dev/null || true
  fi
  if [[ -n "${ERR_FILE:-}" && -f "$ERR_FILE" ]]; then
    rm -f "$ERR_FILE" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

print_usage() {
  cat <<EOF
Usage: lima-sandbox-runner.sh --run-dir <dir> --script <rel-path> [OPTIONS]

Options:
  --run-dir <dir>            Host run directory where results/artifacts are stored
  --poc-id <id>              Identifier for this PoC candidate (default: poc-default)
  --script <path|cmd>        Script file path or shell commands to execute inside container
  --stage <path>             File or directory to stage into container /target (repeatable)
  --cpu <num>                Container CPU limit (default: 1)
  --memory <mem>             Container memory limit (default: 512m)
  --pids <num>               Container PIDs limit (default: 64)
  --wall <seconds>           Maximum wall-clock execution time (default: 60)
  --allowlist-promote <file> Relative file path from scratch to promote (repeatable)
  --auto-exec                Bypass user confirmation gate
  --start-vm                 Automatically start Lima VM if currently stopped
  -h, --help                 Show this help message

Exit codes:
  0   Success (execution finished and result captured in result.json)
  75  Pending/declined approval, or approved.token does not match payload digest
  76  Sandbox control unavailable (VM stopped, missing nerdctl/image/python3)
  77  Artifact promotion rejected (symlink, exceeded limits, path escape)

Approval: this script is the only approval authority. Interactive TTY sessions are
prompted directly. Non-interactive runs print a command for the human to run in
their own terminal; the token binds to the payload sha256, so it cannot be reused
for different PoC content.
EOF
}

# Parse command line flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-dir)
      RUN_DIR="$2"
      shift 2
      ;;
    --poc-id)
      POC_ID="$2"
      shift 2
      ;;
    --script)
      SCRIPT="$2"
      shift 2
      ;;
    --stage)
      STAGE_FILES+=("$2")
      shift 2
      ;;
    --allowlist-promote)
      ALLOWLIST_PROMOTE+=("$2")
      shift 2
      ;;
    --cpu)
      CPU="$2"
      shift 2
      ;;
    --memory)
      MEMORY="$2"
      shift 2
      ;;
    --pids)
      PIDS="$2"
      shift 2
      ;;
    --wall)
      WALL="$2"
      shift 2
      ;;
    --auto-exec)
      AUTO_EXEC=true
      shift
      ;;
    --start-vm)
      START_VM=true
      shift
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      echo "ERROR: Unknown option: $1" >&2
      print_usage
      exit 1
      ;;
  esac
done

if [[ -z "$RUN_DIR" || -z "$SCRIPT" ]]; then
  echo "ERROR: --run-dir and --script are required." >&2
  print_usage
  exit 1
fi

# --- Input validation -------------------------------------------------------
# POC_ID reaches VM paths and result.json. It originates from LLM output, so the
# same charset the report schema enforces on fingerprints is enforced here (C1/C2).
if [[ ! "$POC_ID" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
  echo "ERROR: --poc-id rejected; must match ^[A-Za-z0-9][A-Za-z0-9._-]*$ (no quotes, spaces, slashes, or shell metacharacters)." >&2
  exit 1
fi

# Resource limits are validated and clamped (M1): --wall 999999 used to be accepted.
if [[ ! "$CPU" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
  echo "ERROR: --cpu must be numeric (got: $CPU)" >&2
  exit 1
fi
if [[ ! "$PIDS" =~ ^[0-9]+$ ]]; then
  echo "ERROR: --pids must be an integer (got: $PIDS)" >&2
  exit 1
fi
if [[ ! "$WALL" =~ ^[0-9]+$ ]] || [[ "$WALL" -lt 1 ]] || [[ "$WALL" -gt 900 ]]; then
  echo "ERROR: --wall must be an integer between 1 and 900 seconds (got: $WALL)" >&2
  exit 1
fi
if [[ ! "$MEMORY" =~ ^[0-9]+[bkmgt]?$ ]]; then
  echo "ERROR: --memory must look like 512m, 1g, or plain bytes (got: $MEMORY)" >&2
  exit 1
fi

POC_DIR="$RUN_DIR/sandbox/$POC_ID"
mkdir -p "$POC_DIR" "$POC_DIR/artifacts"

# 1. PREFLIGHT: Fail-closed sandbox verification
if ! command -v limactl >/dev/null 2>&1; then
  echo "[PREFLIGHT FAIL] limactl CLI not found on host." >&2
  exit 76
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "[PREFLIGHT FAIL] python3 not found on host." >&2
  exit 76
fi

VM_STATUS=$(limactl list "$VM_NAME" --json 2>/dev/null | grep -o '"status":"[^"]*"' | head -n1 | cut -d'"' -f4 || echo "unknown")
if [[ "$VM_STATUS" != "Running" ]]; then
  if [[ "$START_VM" == true ]]; then
    echo "[PREFLIGHT] Lima VM '$VM_NAME' is '$VM_STATUS'. Starting VM..." >&2
    limactl start "$VM_NAME" || true
    VM_STATUS=$(limactl list "$VM_NAME" --json 2>/dev/null | grep -o '"status":"[^"]*"' | head -n1 | cut -d'"' -f4 || echo "unknown")
  fi
fi

if [[ "$VM_STATUS" != "Running" ]]; then
  echo "[PREFLIGHT FAIL] Lima VM '$VM_NAME' status is '$VM_STATUS' (must be Running). Run 'limactl start $VM_NAME' or pass --start-vm." >&2
  exit 76
fi

if ! lima --instance "$VM_NAME" nerdctl --version >/dev/null 2>&1; then
  echo "[PREFLIGHT FAIL] nerdctl not found inside VM '$VM_NAME'." >&2
  exit 76
fi

if ! lima --instance "$VM_NAME" nerdctl image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "[PREFLIGHT FAIL] Image '$IMAGE' not found in VM '$VM_NAME' nerdctl store." >&2
  exit 76
fi

# 2. CONFIRMATION GATE — the runner is the sole approval authority (C3).
# The orchestrating LLM must NOT create the token itself: approval is attested by
# the human running the printed command in their own terminal, and the token binds
# to the exact payload digest so a stale or forged token cannot authorize new code.
TOKEN_FILE="$POC_DIR/approved.token"

if [[ -f "$SCRIPT" ]]; then
  PAYLOAD_SHA=$(sha256sum "$SCRIPT" | cut -d' ' -f1)
else
  PAYLOAD_SHA=$(printf '%s\n' "$SCRIPT" | sha256sum | cut -d' ' -f1)
fi

if [[ "$AUTO_EXEC" != true && ! -f "$TOKEN_FILE" ]]; then
  if [[ -t 0 && -e /dev/tty ]]; then
    cat <<APPROVAL_PROMPT
================================================================================
LIMA SANDBOX POC CONFIRMATION GATE
================================================================================
PoC ID:      $POC_ID
Payload:     sha256=$PAYLOAD_SHA
Image:       $IMAGE (unprivileged uid 65532, cap-drop=ALL)
Limits:      CPU=$CPU, Mem=$MEMORY, Pids=$PIDS, Wall=${WALL}s
Network:     NONE (isolated loopback only)
Target:      READ-ONLY
Staged:      ${STAGE_FILES[*]:-none}
Output Dir:  $POC_DIR

Execute this PoC inside the Lima container? [y/N]
APPROVAL_PROMPT
    read -r answer </dev/tty
    if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
      echo "[GATE] Approval declined." >&2
      exit 75
    fi
    printf 'sha256=%s\napproved_at=%s\n' "$PAYLOAD_SHA" "$(date -u +%FT%TZ)" > "$TOKEN_FILE"
  else
    # Non-interactive (LLM-invoked): refuse to self-approve, hand the human the command.
    cat <<APPROVAL_PROMPT
================================================================================
LIMA SANDBOX POC CONFIRMATION GATE — HUMAN APPROVAL REQUIRED
================================================================================
Non-interactive invocation detected. To approve, run this command in YOUR OWN
terminal (never delegate token creation to the orchestrator):

  printf 'sha256=%s\napproved_at=%s\n' "$PAYLOAD_SHA" "$(date -u +%FT%TZ)" > "$TOKEN_FILE"

Then re-run this script. The token is bound to payload sha256=$PAYLOAD_SHA;
any change to the PoC payload invalidates it.
================================================================================
APPROVAL_PROMPT
    exit 75
  fi
fi

# A token that does not match the current payload is stale or forged — reject it.
if [[ -f "$TOKEN_FILE" ]]; then
  TOKEN_SHA=$(grep -o 'sha256=[a-f0-9]\{64\}' "$TOKEN_FILE" | head -n1 | cut -d= -f2 || true)
  if [[ -z "$TOKEN_SHA" || "$TOKEN_SHA" != "$PAYLOAD_SHA" ]]; then
    echo "ERROR: approved.token does not match current payload digest ($PAYLOAD_SHA). Re-approval required." >&2
    exit 75
  fi
fi

# 3. STAGING: Copy files into VM sandbox scratch space
# POC_ID is deliberately excluded from VM_BASE: this path is interpolated into
# remote `sh -c` strings, and POC_ID originates from LLM output (C2).
VM_BASE="/tmp/secaudit-$(date +%s)-$RANDOM-$$"
VM_TARGET="$VM_BASE/target"
VM_SCRATCH="$VM_BASE/scratch"

# All remote shell commands receive paths positionally ("$1") — never interpolated.
run_with_timeout 60 lima --instance "$VM_NAME" sh -c 'rm -rf "$1" && mkdir -p "$1/target" "$1/scratch" && chmod 1777 "$1/scratch"' _ "$VM_BASE"

if [[ ${#STAGE_FILES[@]} -gt 0 ]]; then
  # Stage files into VM using relative paths
  STAGE_TAR=$(mktemp "/tmp/secaudit-stage-XXXXXX.tar")
  tar -cf "$STAGE_TAR" "${STAGE_FILES[@]}"
  cat "$STAGE_TAR" | run_with_timeout 120 lima --instance "$VM_NAME" tar -xf - -C "$VM_TARGET"
  rm -f "$STAGE_TAR"
fi

# Stage SCRIPT directly as an executable file inside VM_TARGET (eliminates shell interpolation escape)
if [[ -f "$SCRIPT" ]]; then
  cat "$SCRIPT" | run_with_timeout 60 lima --instance "$VM_NAME" sh -c 'cat > "$1/run-poc.sh" && chmod 755 "$1/run-poc.sh"' _ "$VM_TARGET"
else
  printf '%s\n' "$SCRIPT" | run_with_timeout 60 lima --instance "$VM_NAME" sh -c 'cat > "$1/run-poc.sh" && chmod 755 "$1/run-poc.sh"' _ "$VM_TARGET"
fi

# 4. EXECUTION: Run unprivileged in container with no network & strict security limits
START_TS=$(python3 -c 'import time; print(int(time.time()*1000))')
OUT_FILE=$(mktemp "/tmp/secaudit-out-XXXXXX")
ERR_FILE=$(mktemp "/tmp/secaudit-err-XXXXXX")

set +e
lima --instance "$VM_NAME" timeout "$WALL" nerdctl run --rm \
  --network none \
  --read-only \
  --cap-drop=ALL \
  --security-opt no-new-privileges \
  --cpus "$CPU" \
  --memory "$MEMORY" \
  --pids-limit "$PIDS" \
  --user 65532:65532 \
  --tmpfs /tmp:rw,size=64m \
  -v "$VM_TARGET":/target:ro \
  -v "$VM_SCRATCH":/scratch:rw \
  -w /target \
  "$IMAGE" sh /target/run-poc.sh > "$OUT_FILE" 2> "$ERR_FILE"
CONTAINER_EXIT=$?
set -e

END_TS=$(python3 -c 'import time; print(int(time.time()*1000))')
DURATION_MS=$(( END_TS - START_TS ))

# Save stdout / stderr
cat "$OUT_FILE" > "$POC_DIR/stdout.log"
cat "$ERR_FILE" > "$POC_DIR/stderr.log"

# Generate JSON result — all values passed via environment, never interpolated
# into the Python source (C1: a quote in POC_ID used to escape the literal).
POC_ID="$POC_ID" OUT_FILE="$OUT_FILE" ERR_FILE="$ERR_FILE" \
CONTAINER_EXIT="$CONTAINER_EXIT" DURATION_MS="$DURATION_MS" \
CPU="$CPU" MEMORY="$MEMORY" PIDS="$PIDS" WALL="$WALL" \
POC_DIR="$POC_DIR" python3 -c '
import json, datetime, os

stdout = open(os.environ["OUT_FILE"], "r", errors="replace").read()
stderr = open(os.environ["ERR_FILE"], "r", errors="replace").read()

result = {
    "poc_id": os.environ["POC_ID"],
    "exit_code": int(os.environ["CONTAINER_EXIT"]),
    "stdout": stdout,
    "stderr": stderr,
    "wall_time_ms": int(os.environ["DURATION_MS"]),
    "executed_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "limits": {
        "cpu": os.environ["CPU"],
        "memory": os.environ["MEMORY"],
        "pids": os.environ["PIDS"],
        "wall": os.environ["WALL"],
    },
}

with open(os.path.join(os.environ["POC_DIR"], "result.json"), "w") as f:
    json.dump(result, f, indent=2)
'

rm -f "$OUT_FILE" "$ERR_FILE"

# 5. PROMOTION: Parent-side promotion of allowlisted files only
if [[ ${#ALLOWLIST_PROMOTE[@]} -gt 0 ]]; then
  for item in "${ALLOWLIST_PROMOTE[@]}"; do
    # Validate no path escape and no shell metacharacters (C2: promotion paths
    # used to be interpolated into a remote sh -c string).
    if [[ "$item" == /* || "$item" == *".."* || ! "$item" =~ ^[A-Za-z0-9._/-]+$ ]]; then
      echo "ERROR: Disallowed promotion path (absolute, parent dir, or illegal characters): $item" >&2
      exit 77
    fi

    # Check item status inside VM scratch — path passed positionally.
    CHECK_VM=$(run_with_timeout 60 lima --instance "$VM_NAME" sh -c '
      if [ -L "$1" ]; then echo "SYMLINK";
      elif [ -f "$1" ]; then echo "REGULAR";
      else echo "MISSING"; fi
    ' _ "$VM_SCRATCH/$item")

    if [[ "$CHECK_VM" == "SYMLINK" ]]; then
      echo "ERROR: Artifact '$item' is a symlink, promotion rejected." >&2
      exit 77
    elif [[ "$CHECK_VM" != "REGULAR" ]]; then
      echo "WARN: Expected artifact '$item' was not produced in scratch." >&2
      continue
    fi

    mkdir -p "$(dirname "$POC_DIR/artifacts/$item")"
    run_with_timeout 60 lima --instance "$VM_NAME" cat "$VM_SCRATCH/$item" > "$POC_DIR/artifacts/$item"
  done
fi

echo "[SUCCESS] PoC execution finished for $POC_ID with container exit code $CONTAINER_EXIT (duration: ${DURATION_MS}ms)"
exit 0
