# Riset: Skill Domain Bisnis untuk Dashboard (`/build-dashboard` Phase 0)

- **Tanggal**: 2026-11-03
- **Metode**: `/deep-research` 5-fase — Phase 0 grounding ke 312 skill ECC existing (pada waktu scan; repositori kini 315 setelah tiga skill di bawah dibuat), Phase 2 pencarian eksternal (websearch + GitHub + webfetch katalog awesome), Phase 3 adversarial pass, Phase 4 sintesis ini.
- **Pertanyaan**: Apakah ada skill domain bisnis yang bagus di internet dan bisa diadopsi untuk memperkaya dispatch table `/build-dashboard` Phase 0?

## Phase 0 — Grounding: apa yang sudah dicover ECC

Scan 393 direktori skill (312 repo + global) terhadap 20 bucket domain bisnis. Hasil:

**Sudah dicover (11 skill domain dengan vocabulary KPI nyata):**
`inventory-demand-planning`, `production-scheduling`, `logistics-exception-management`, `carrier-relationship-management`, `returns-reverse-logistics`, `customs-trade-compliance`, `quality-nonconformance`, `energy-procurement`, `customer-billing-ops`, `finance-billing-ops`, `market-research` — plus lapisan generik `dashboard-builder` + `product-lens`.

**Gap teridentifikasi (0 skill, vocabulary KPI tersedia):**

| Gap | KPI inti yang belum terwakili |
| :--- | :--- |
| HR / people ops | regretted attrition by cohort, time to fill, offer acceptance, compa-ratio, adjusted pay-equity gap, span of control |
| Retail / e-commerce merchandising | sell-through, GMROI, weeks of supply, conversion by channel, markdown cadence, margin erosion decomposition |
| Insurance operations | combined ratio, loss ratio by accident year + development, severity median/P90, claims leakage, concentration by peril |
| Telecom operations | ARPU, subscriber churn, SAC, network availability, MOU |
| Real estate / property | occupancy, NOI, cap rate, WALT, rent roll, collections |

## Phase 2 — Pencarian eksternal

Sumber yang diperiksa:

1. **ComposioHQ/awesome-claude-skills** (78.7k stars, 1000+ skill) — kategori lengkap dibaca: Document Processing, Development & Code Tools, Data & Analysis, Business & Marketing, Communication & Writing, Creative & Media, Productivity, Collaboration, Security, App Automation (78 SaaS).
2. **VoltAgent/awesome-agent-skills** (1000+ skill, cross-harness).
3. **alirezarezvani/claude-skills** (411 skill, 20 domain).
4. **skills.sh** directory, awesome-skills.com, dan listing artikel "Top Claude Skills 2026".

### Temuan

**Tidak ada skill luar yang bisa diadopsi untuk kelima gap domain.**

Yang tersedia di luar hanya:

- **CRM/SaaS automation skills** (Salesforce, HubSpot, Pipedrive, Close, Zoho, Intercom) — ini *urutan tool* ("how to call the API"), bukan *vocabulary metrik* ("what to measure, formula, ambang tindak"). Tidak menjawab pertanyaan Phase 0.
- **`Master Claude for Legal`** (sboghossian) — satu-satunya pack domain non-teknis yang ditemukan; domain legal, bukan KPI bisnis.
- **`rampstackco/claude-skills`** (59 skill: brand, design, content, SEO, dev, ops, growth, research) — pemasaran/web lifecycle, bukan operasional bisnis.
- **`CSV Data Summarizer`**, **`deep-research`** (sanjay3290) — analisis generik, bukan domain.

Kesimpulan adversarial: komunitas skill mengoptimalkan untuk *development workflow* dan *app automation*, bukan *business domain knowledge*. Gap-nya nyata dan tidak terisi oleh ekosistem.

## Phase 3 — Keputusan

Sesuai fork owner ("buat skill baru hanya untuk domain yang belum dicover ECC"), tiga skill dibuat untuk gap dengan vocabulary paling terstandar dan aplikasi dashboard paling luas:

1. **`people-analytics`** — HR & workforce operations
2. **`retail-merchandising-analytics`** — retail & e-commerce merchandising
3. **`insurance-operations-analytics`** — insurance underwriting, claims, dan konversi

Tidak dibuat (ditunda, YAGNI): `telecom-operations-analytics` dan `real-estate-property-analytics`. Vocabulary keduanya jelas (ARPU/churn/SAC; occupancy/NOI/cap rate/WALT) dan bisa ditambahkan kapan saja dengan pola wiring yang sama — buat hanya bila ada dashboard aktual untuk domain tersebut.

## Catatan reuse

Pola setiap skill baru: role & context → When to Use → How It Works → Core Knowledge (metrik dengan formula, ambang, dan jebakan interpretasi) → Dashboard Guidance (tabel pertanyaan→metrik→keputusan) → Anti-Patterns → Related Skills. Pola ini sengaja membuat hard gate Phase 0 bisa dieksekusi: setiap metrik punya "keputusan yang digerakkan" yang sudah tertulis.

Wiring surface wajib per skill baru: `package.json` `files[]`, `manifests/install-modules.json`, `agent.yaml`, `npm run catalog:sync`, `.agents/skills/<nama>/SKILL.md` + `.agents/skills/<nama>/agents/openai.yaml`.

Catatan salinan Codex (`.agents/skills/<nama>/`): frontmatter-nya **sengaja dipangkas** ke key yang diizinkan validator Codex (`name`, `description`, `metadata`, `license`, `allowed-tools`). Key top-level lain seperti `homepage` dibuang, sehingga diff permanen terhadap salinan repo adalah expected — jangan "perbaiki" dengan menyalin balik. Isi `metadata` (version, origin, author, clawdbot) dipertahankan utuh karena `metadata` sendiri key yang diizinkan.
