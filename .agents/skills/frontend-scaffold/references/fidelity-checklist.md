# Composition Fidelity Checklist

Companion to `frontend-scaffold` Phase 5. The token audit file proves token
compliance; this gate proves the render matches the reference. Two layers, both
mandatory.

## 1. What this gate is

A measured, per-section comparison of the running render against the page
contract's Section 5 (Composition Spec). It runs as a separate layer after the
token audit — verification is its own step, not a byproduct of building
(OverlayQA pattern). Each row returns PASS / FAIL / UNMEASURABLE with observed
vs expected values.

## 2. What this gate is NOT

Not a pixel diff. Pixel diff is brittle to content changes (text wraps, imagery
swaps, locale switches) and cannot express a normative "should". Owner decision,
do not revisit. The checklist compares *structure*, not screenshots.

## 3. Run it

1. Start the dev server (or `astro preview` / `next dev`, per project).
2. Capture the render at 1440 / 768 / 375.
3. Dispatch `multimodal-looker` with **both** the reference image and the
   screenshots, plus the contract's §5 tables:

```
subagent(agent="multimodal-looker", description="Composition fidelity verification")
"Compare the reference image at `<reference-path>` against these screenshots of our
render: <screenshot-paths>. The contract's Composition Spec (Section 5) defines the
expected values. For EACH row — per-section container width and padding, grid/span
ratio, per-element alignment, nav position + material + z tier, per-element font
size/weight, image treatment — report: expected (from the spec), observed, and a
verdict of PASS / FAIL / UNMEASURABLE. Give numbers. Do not judge aesthetics;
judge structure only. Output one row per field."
```

4. Record every row with its verdict and evidence.

## 4. Row schema

| Field | Content |
|---|---|
| Section + field | e.g. `Topbar / layout` |
| Expected | the §5 value, verbatim |
| Observed | measured from the render |
| Verdict | PASS / FAIL / UNMEASURABLE |
| Fix | the code change for a FAIL (never a spec change) |

## 5. Verdict rules

- A FAIL means change the render, never the checklist.
- `UNMEASURABLE` (text not rendered yet, asset pending, section behind a flag)
  is recorded and re-run later — it is not a pass.
- Token-audit green does not imply fidelity PASS. The layers are independent.
- The gate is not satisfiable by self-attestation: the `multimodal-looker`
  dispatch is mandatory evidence. "Looks right to me" is not a verdict.

## 6. Fix loop

Fix, re-capture, re-dispatch. Maximum two loops per section. A third failure
means the contract's §5 is wrong, not the code — stop and escalate to the
contract owner with both dispatches attached.

## 7. Anti-Patterns

- Passing a section because the token audit is green.
- Editing the expected values to match a broken render (self-approval — the
  same failure class the canonical audit file exists to prevent).
- Skipping the 375px capture because "it is a desktop page".
- Accepting adjectives ("close enough", "similar spacing") in the observed
  column.
- Running the gate before the §5 spec exists — Phase 0 fails closed first.
