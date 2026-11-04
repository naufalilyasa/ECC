#!/usr/bin/env node

/**
 * Validates run-metadata.json for the /security-audit terminal state.
 * Usage: node validate-run-metadata.cjs <RUN_DIR>
 *
 * Exit 0 when the run is either:
 *   - run_status "complete"  AND all three Phase 6 reports exist on disk, or
 *   - run_status "incomplete" AND a non-empty incomplete_reason is stated.
 * Exit 1 otherwise. Dependency-free.
 */

const fs = require("fs");
const path = require("path");

const REQUIRED_STRINGS = ["repo_name", "source_ref", "run_status", "generated_at"];
const REQUIRED_REPORTS = ["REPORT.md", "FINDINGS-DETAIL.md", "NEEDS-VALIDATION.md"];
const TERMINAL_STATES = new Set(["complete", "incomplete"]);

function fail(message) {
  console.error("ERROR:", message);
  return 1;
}

function run(runDir) {
  if (!runDir) {
    return fail("usage: node validate-run-metadata.cjs <RUN_DIR>");
  }

  const file = path.join(runDir, "run-metadata.json");
  let raw;
  try {
    raw = fs.readFileSync(file, "utf8");
  } catch {
    return fail(`cannot read ${file}`);
  }

  let meta;
  try {
    meta = JSON.parse(raw);
  } catch {
    return fail("run-metadata.json is not valid JSON");
  }

  if (meta === null || typeof meta !== "object" || Array.isArray(meta)) {
    return fail("run-metadata.json must be a JSON object");
  }

  for (const key of REQUIRED_STRINGS) {
    if (typeof meta[key] !== "string" || meta[key].length === 0) {
      return fail(`missing or empty required field: ${key}`);
    }
  }

  if (!TERMINAL_STATES.has(meta.run_status)) {
    return fail(`run_status must be "complete" or "incomplete" (got: ${meta.run_status})`);
  }

  if (meta.run_status === "incomplete") {
    if (typeof meta.incomplete_reason !== "string" || meta.incomplete_reason.length === 0) {
      return fail('run_status "incomplete" requires a non-empty incomplete_reason');
    }
    console.log("PASS: run recorded as incomplete with stated reason");
    return 0;
  }

  const missing = REQUIRED_REPORTS.filter((name) => !fs.existsSync(path.join(runDir, name)));
  if (missing.length > 0) {
    return fail(`run_status "complete" but missing Phase 6 report(s): ${missing.join(", ")}`);
  }

  console.log("PASS: run complete with all Phase 6 reports present");
  return 0;
}

if (require.main === module) process.exit(run(process.argv[2]));

module.exports = { run };
