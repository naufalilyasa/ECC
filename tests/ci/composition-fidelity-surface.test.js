const assert = require('assert');
const fs = require('fs');
const path = require('path');

const REPO_ROOT = path.resolve(__dirname, '..', '..');

// Scoped to the two skills touched by the visual-fidelity plan. The wider
// .agents/skills surface is heterogeneous (verbatim mirrors, transform-only
// mirrors, Codex-only skills) and must not be asserted with one transform.
const SKILLS = ['design-contract-system', 'frontend-scaffold'];

const NEW_FILES = {
  'design-contract-system': [
    ['references', 'composition-extraction.md'],
    ['references', 'anti-slop-rules.md'],
    ['templates', 'page-contract.md'],
  ],
  'frontend-scaffold': [
    ['references', 'fidelity-checklist.md'],
  ],
};

const CONTENT_MARKERS = [
  [
    path.join('skills', 'design-contract-system', 'templates', 'page-contract.md'),
    '## 5. Composition Spec',
  ],
  [
    path.join('skills', 'design-contract-system', 'SKILL.md'),
    'references/composition-extraction.md',
  ],
  [
    path.join('skills', 'frontend-scaffold', 'SKILL.md'),
    'references/fidelity-checklist.md',
  ],
  [
    path.join('skills', 'frontend-scaffold', 'SKILL.md'),
    'Composition fidelity gate',
  ],
  [
    path.join('skills', 'design-contract-system', 'references', 'anti-slop-rules.md'),
    'Composition Rules',
  ],
];

const HOME = process.env.HOME || '';
const GLOBAL_SKILLS = path.join(HOME, '.config', 'opencode', 'skills');

function read(file) {
  return fs.readFileSync(file, 'utf8');
}

function splitFrontmatter(text) {
  const match = text.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
  assert.ok(match, 'missing YAML frontmatter');
  return { frontmatter: match[1], body: match[2] };
}

// The Codex mirror transform: drop metadata/origin, add license: MIT, unquote
// the description scalar. Body must stay byte-identical.
function expectedCodexBody(canonicalText) {
  const { frontmatter, body } = splitFrontmatter(canonicalText);
  const name = frontmatter.match(/^name:\s*(.+)$/m)[1].trim();
  let description = frontmatter.match(/^description:\s*(.+)$/m)[1].trim();
  if (
    (description.startsWith('"') && description.endsWith('"')) ||
    (description.startsWith("'") && description.endsWith("'"))
  ) {
    description = description.slice(1, -1);
  }
  const expectedFrontmatter = `---\nname: ${name}\ndescription: ${description}\nlicense: MIT\n---`;
  return { expectedFrontmatter, body };
}

let passed = 0;
let failed = 0;

function run() {
  for (const skill of SKILLS) {
    if (test(`${skill}: new files exist in canonical, Codex mirror, and global mirror`, () => {
      for (const segments of NEW_FILES[skill]) {
        const rel = path.join(...segments);
        const canonical = path.join(REPO_ROOT, 'skills', skill, rel);
        const codex = path.join(REPO_ROOT, '.agents', 'skills', skill, rel);
        const globalCopy = path.join(GLOBAL_SKILLS, skill, rel);
        assert.ok(fs.existsSync(canonical), `canonical missing: ${rel}`);
        assert.ok(fs.existsSync(codex), `Codex mirror missing: ${rel}`);
        assert.ok(fs.existsSync(globalCopy), `global mirror missing: ${rel}`);
        assert.strictEqual(read(canonical), read(codex), `Codex mirror diverged: ${rel}`);
        assert.strictEqual(read(canonical), read(globalCopy), `global mirror diverged: ${rel}`);
      }
    })) passed++; else failed++;

    if (test(`${skill}: Codex SKILL.md matches canonical after frontmatter transform`, () => {
      const canonicalText = read(path.join(REPO_ROOT, 'skills', skill, 'SKILL.md'));
      const codexText = read(path.join(REPO_ROOT, '.agents', 'skills', skill, 'SKILL.md'));
      const { expectedFrontmatter, body } = expectedCodexBody(canonicalText);
      const actual = splitFrontmatter(codexText);
      assert.strictEqual(actual.frontmatter, expectedFrontmatter.slice(4, -4), 'frontmatter transform mismatch');
      assert.strictEqual(actual.body, body, 'Codex mirror body diverged from canonical');
      assert.ok(!codexText.includes('origin: ECC'), 'Codex mirror must not carry metadata/origin');
      assert.ok(codexText.includes('license: MIT'), 'Codex mirror must carry license: MIT');
    })) passed++; else failed++;

    if (test(`${skill}: global OpenCode SKILL.md is a verbatim copy`, () => {
      const canonical = read(path.join(REPO_ROOT, 'skills', skill, 'SKILL.md'));
      const globalCopy = read(path.join(GLOBAL_SKILLS, skill, 'SKILL.md'));
      assert.strictEqual(globalCopy, canonical, 'global mirror diverged from canonical');
    })) passed++; else failed++;
  }

  for (const [file, marker] of CONTENT_MARKERS) {
    if (test(`content marker present: ${marker} in ${path.relative(REPO_ROOT, file)}`, () => {
      assert.ok(read(path.join(REPO_ROOT, file)).includes(marker), `missing marker: ${marker}`);
    })) passed++; else failed++;
  }

  console.log(`\nPassed: ${passed}`);
  console.log(`Failed: ${failed}`);
  process.exit(failed > 0 ? 1 : 0);
}

function test(name, fn) {
  try {
    fn();
    console.log(`  ok - ${name}`);
    return true;
  } catch (error) {
    console.log(`  not ok - ${name}`);
    console.log(`    ${error.message}`);
    return false;
  }
}

run();
