"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");

const { run } = require("./validate-run-metadata.cjs");

function withRunDir(fn) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "secaudit-meta-"));
  try {
    return fn(dir);
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

function writeMeta(dir, meta) {
  fs.writeFileSync(path.join(dir, "run-metadata.json"), JSON.stringify(meta, null, 2));
}

const BASE_META = {
  repo_name: "demo",
  source_ref: "abc1234",
  generated_at: "2026-11-04T00:00:00Z",
};

test("complete run requires all three Phase 6 reports on disk", () => {
  withRunDir((dir) => {
    writeMeta(dir, { ...BASE_META, run_status: "complete" });
    assert.equal(run(dir), 1, "missing reports must fail");
    for (const name of ["REPORT.md", "FINDINGS-DETAIL.md", "NEEDS-VALIDATION.md"]) {
      fs.writeFileSync(path.join(dir, name), "stub");
    }
    assert.equal(run(dir), 0, "complete run with reports must pass");
  });
});

test("incomplete run requires a stated reason", () => {
  withRunDir((dir) => {
    writeMeta(dir, { ...BASE_META, run_status: "incomplete" });
    assert.equal(run(dir), 1, "incomplete without reason must fail");
    writeMeta(dir, { ...BASE_META, run_status: "incomplete", incomplete_reason: "budget exhausted" });
    assert.equal(run(dir), 0, "incomplete with reason must pass");
  });
});

test("unknown run_status and missing fields are rejected", () => {
  withRunDir((dir) => {
    writeMeta(dir, { ...BASE_META, run_status: "partial" });
    assert.equal(run(dir), 1);
    writeMeta(dir, { run_status: "complete" });
    assert.equal(run(dir), 1);
  });
});

test("missing usage argument fails", () => {
  assert.equal(run(undefined), 1);
});
