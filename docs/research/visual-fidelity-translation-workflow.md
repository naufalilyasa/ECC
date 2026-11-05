# Riset: Workflow Penerjemahan Referensi Visual → Frontend High-Fidelity

**Tanggal**: 2026-11-05
**Konteks**: Build landing page kreasi-lima-pilar-teknologi (Astro) terhadap referensi `compro1.webp` (Rastekindo). Setelah dua round perbaikan, komposisi struktur besar sudah sesuai (hero full-bleed, galeri 1+3, dark horizontal-scroll), tetapi detail masih miss: hero tanpa image-gen background, topbar bukan liquid-glass floating (logo center + search + Contact Us kanan), font size berbeda, galeri asimetris belum sama, section "Fondasi Rekayasa" beda, blog/news layout + font beda, CTA "Konsultasi Solusi Industri" harus rata tengah, footer belum mirip.

## Executive Summary

**Tidak ada skill eksternal yang bisa diadopsi mentah** untuk menyelesaikan masalah ini. Yang ada di internet either (a) terkopla platform (Google stitch-skills butuh Stitch MCP, dan arahnya design→prompt descriptive, bukan image→code presisi), atau (b) punya ceiling fidelity 20-40% cleanup (v0, Locofy, Anima, Builder.io — "missing elements and wrong layout" adalah dua error paling umum menurut Design2Code). **Gap sebenarnya ada di dalam skill ECC sendiri**: `design-contract-system` Phase 1 mengekstrak token (warna/radius/spacing) tapi tidak mengukur **komposisi** (grid, alignment, asimetri, scroll-behavior, sticky nav, per-element typography); `frontend-scaffold` Phase 5 hanya audit token, tidak ada **fidelity gate** terhadap referensi. Rekomendasi: extend dua skill itu dengan Composition Extraction Protocol + Composition Contract section + Fidelity Checklist — bukan bikin skill baru dari nol.

## Codebase Context & Compatibility

Stack ECC yang relevan (terverifikasi di disk):
- `skills/design-contract-system/SKILL.md` — Phase 1 ekstraksi DNA visual (token-level), Phase 3 page-contract (Bento grid 3 breakpoint), Phase 4 audit grep token
- `skills/frontend-scaffold/SKILL.md` — Phase 0 kontrak → Phase 5 audit token (3 grep kanonik + spacing)
- `multimodal-looker` agent — analisis visual screenshot (Gemini Flash)
- `skills/make-interfaces-feel-better/SKILL.md` — micro-polish (concentric radius, optical alignment, text-wrap balance)
- `skills/liquid-glass-design/SKILL.md` — pola glass material
- `experimental_image_generate` tool — 4 model Cloudflare Workers AI (flux-2-klein dll)

**Yang sudah bekerja**: token audit 19/19 hijau di project; HOME-CONTRACT.md sudah jadi otoritas komposisi (ditulis ulang manual dari referensi); hero/galeri/dark-section sudah di-rewrite sesuai struktur referensi.

**Yang tidak bekerja**: kontrak awal lahir dari reinterpretasi prosa, bukan ekstraksi terukur dari gambar; audit gate hanya token-level; tidak ada checklist komposisi per-section yang menghubungkan "yang dilihat di referensi" dengan "yang di-render di browser".

## Key Findings

### 1. Eksternal: tidak ada silver bullet

| Sumber | Temuan | Relevansi |
|---|---|---|
| [AgentSkillsHub — 197 graded design skills](https://agentskillshub.top/best/ai-design/) | "Missing elements and wrong layout are the two errors Design2Code found most" | **Persis keluhan user** — masalah industri, bukan cuma kita |
| [Dupple — Screenshot to Code 2026](https://dupple.com/blog/screenshot-to-code) | "AI handles the boring 70%. You still own architecture, accessibility, state management, and design-system fidelity" — 20-40% manual cleanup | Tools eksternal punya ceiling yang sama |
| [Vibe Coder — v0 vs Builder vs Locofy](https://blog.vibecoder.me/figma-to-code-tools-workflows-compared) | v0 "captures the overall feel... often misses exact spacing values, specific font weights, and subtle interaction details" | **Persis**: font size miss = klasik v0-class error |
| [Banani — Design-to-Code Guide 2026](https://www.banani.co/blog/ai-design-to-code-tools) | "Accuracy is directly proportional to design discipline" | Kontrak longgar → output longgar |
| [OverlayQA](https://overlayqa.com/blog/design-to-code-tools/) | Kategori tool tersendiri: verification layer yang konfirmasi output match design | Pola benar: verification sebagai lapis terpisah |

### 2. Google stitch-skills (8.5k★) — referensi, bukan adopsi

[google-labs-code/stitch-skills](https://github.com/google-labs-code/stitch-skills) adalah library skill paling matang untuk design-to-code agent, tapi:
- `design-md` skill (deep-read): butuh **Stitch MCP server** (tidak terkonfigurasi), dan output-nya DESIGN.md **descriptive language** ("Pill-shaped", "gently curved edges") untuk *prompting Stitch generate screens* — arahnya design→prompt, bukan image→implementation. Presisi teknisnya lebih lemah dari `design-contract-system` kita (yang langsung produces hex + token + Tailwind mapping).
- `taste-design` punya layout rules yang bagus ("three equal cards row is banned", "min-h-[100dvh]", "single-column below 768px", "44px touch targets") — **nilai ini bisa diadaptasi** sebagai composition rules, tapi sebagai bagian dari skill kita, bukan instalasi repo Google.

**Kesimpulan**: adaptasi konsep (composition-aware extraction + taste rules), jangan adopsi paket.

### 3. Akar masalah di project kita (terverifikasi dari 8 keluhan user)

Semua keluhan user adalah **composition-level**, bukan token-level:

| Keluhan | Kelangan spec | Layer |
|---|---|---|
| Hero tanpa image-gen | Hero background image sebagai extraction target + prompt spec | Komposisi + asset routing |
| Topbar bukan liquid glass floating (logo center, search + Contact Us kanan) | Nav composition: position, glass material, grid 3-zone (left nav / center logo / right actions) | Komposisi + material |
| Font size tidak sama | Per-element typography scale dari referensi (H1/H2/body/eyebrow sizes + weights) | Tipografi terukur |
| Galeri asimetris tidak sama | Grid ratio 1-tall : 3-stacked + image treatment | Komposisi |
| "Fondasi Rekayasa" section tidak sama | Section layout pattern (eyebrow + headline + scroll track) | Komposisi |
| Blog/news layout + font beda | Card grid ratio, date/title/link typography | Komposisi + tipografi |
| CTA "Konsultasi Solusi Industri" harus rata tengah | Alignment spec per section | Komposisi |
| Footer tidak mirip | 3-column structure + logo/social row + bottom bar | Komposisi |

## Adversarial Trade-offs

- **"Kenapa tidak pakai v0/Locofy langsung?"** — SaaS eksternal ($/mo), output butuh 20-40% cleanup, tidak ada governance kontrak, tidak masuk agent workflow. Kalah dengan extend skill sendiri yang sudah terintegrasi token audit + contract gate.
- **"Kenapa tidak screenshot-diff otomatis?"** — Brittle: konten berubah (teks, gambar) → diff noisy; tidak bisa mengekspresikan "seharusnya" (normative). Checklist komposisi terukur per-section lebih tepat (keputusan owner dari round sebelumnya: B, bukan pixel-diff).
- **"Kenapa tidak skill baru dari nol?"** — `design-contract-system` + `frontend-scaffold` sudah punya rantai kontrak, token audit, Codex mirror, wiring. Skill baru = duplikasi infrastruktur + drift baru (pola yang sudah kita hukum di `a11y` consolidation).
- **Risiko extend**: prompt bloat di kedua skill. Mitigasi: extraction protocol jadi reference file terpisah (`references/composition-extraction.md`), fidelity checklist jadi template file (`templates/fidelity-checklist.md`) — progressive disclosure, SKILL.md tetap ramping.

## Actionable Recommendation

**Extend, jangan bikin baru.** Tiga artefak:

1. **`design-contract-system/references/composition-extraction.md`** (baru) — protokol ekstraksi komposisi dari referensi visual via `multimodal-looker`: per-section capture (grid structure, alignment, ratio asimetri, scroll/floating behavior, per-element typography size+weight, image treatment + image-gen prompt spec). Phase 1 SKILL.md ditambah 1 langkah: "extract composition spec, bukan hanya token".
2. **`design-contract-system/templates/page-contract.md`** — Section baru "Composition Spec" (layout structure per section + alignment + behavior + measured typography table + image asset list dengan prompt).
3. **`frontend-scaffold/SKILL.md` Phase 5** — fidelity checklist: selain 3 grep token, verifikasi composition spec per-section terhadap render (dev server + `multimodal-looker` bandingkan struktur: alignment, grid ratio, nav behavior, font sizes). Pola dari OverlayQA: verification sebagai lapis eksplisit.
4. **Bonus adaptasi dari stitch taste-design**: composition rules di `anti-slop-rules.md` (three-equal-cards-row ban, single-column <768px, 44px touch target — sudah sebagian ada, lengkapi).

**Effort**: Short (2-4h) — 2 file baru + 3 edit SKILL.md/template + validators + wiring (Codex mirror, catalog, global mirror). Siap untuk `/plan visual-fidelity-workflow`.

## Catatan Kejujuran Sumber

- Klaim "20-40% cleanup" dan "missing elements + wrong layout = 2 error teratas" berasal dari artikel industri (Dupple, AgentSkillsHub), bukan paper akademik — indikatif, konsisten lintas 4+ sumber independen.
- stitch-skills dibaca langsung dari repo (8.5k★, Google Labs) — fakta struktur terverifikasi.
- Exa MCP mengembalikan 0 hasil untuk 4 query (keterbatasan harness berulang); riset ini memakai `websearch` + `webfetch` deep-read sebagai fallback.
