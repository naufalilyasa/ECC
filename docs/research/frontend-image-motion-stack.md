# Riset: Generate Image & Motion untuk Kebutuhan Frontend

**Tanggal**: 2026-11-04
**Pertanyaan**: Untuk bikin generate image dan motion (animasi) frontend, pakai skill/command/agent apa yang ada saat ini? Kalau tidak ada, yang mana dari internet yang terbaik?

## Executive Summary

**Semua kapabilitas inti sudah ada di setup saat ini.** Image: skill direction `imagegen-frontend-web`/`-mobile` + tool eksekusi `experimental_image_generate` + agent analisis `multimodal-looker` + command loop `gan-design`. Motion: keluarga skill `motion-foundations` → `motion-patterns` → `motion-advanced` (stack `motion/react` — konsensus 2026, MIT, hardware-accelerated). Satu-satunya gap nyata: tidak ada image-generation API terprogram (MCP) untuk batch/consistent output; skill `fal-ai-media` ada tetapi MCP-nya tidak dikonfigurasi. Rekomendasi internet hanya jika gap itu diperlukan: **fal.ai** (paling cepat, katalog luas, kredit $20) atau **OpenAI gpt-image** (text rendering terbaik untuk UI mockup). Untuk motion: tidak perlu apa pun dari internet — `motion/react` sudah pilihan default yang benar; GSAP hanya jika butuh scroll-choreography/SVG-heavy.

## Codebase Context & Compatibility

### Yang sudah ada (terverifikasi di disk)

| Kebutuhan | Aset | Lokasi | Status |
|---|---|---|---|
| Image direction | `imagegen-frontend-web` | `~/.agents/skills/imagegen-frontend-web/` | aktif (harness skill list) |
| Image direction (mobile) | `imagegen-frontend-mobile` | `~/.agents/skills/imagegen-frontend-mobile/` | aktif |
| Image execution | `experimental_image_generate` (tool) | harness built-in | aktif |
| Image analysis | `multimodal-looker` (agent) | `.opencode/opencode.json` agent block | aktif, model gemini-flash |
| Design gen-eval loop | `gan-design` (command) | `commands/gan-design.md` | aktif |
| Motion foundation | `motion-foundations` (skill) | `skills/motion-foundations/` | aktif |
| Motion patterns | `motion-patterns` (skill) | `skills/motion-patterns/` | aktif |
| Motion advanced | `motion-advanced` (skill) | `skills/motion-advanced/` | aktif |
| Video in React | `remotion-video-creation` (skill) | `skills/remotion-video-creation/` | aktif |
| Animated decks | `frontend-slides` (skill) | `skills/frontend-slides/` | aktif |
| Media via fal.ai | `fal-ai-media` (skill) | `skills/fal-ai-media/` | **MATI** — MCP `fal` tidak ada di `opencode.jsonc` |
| Contract → skeleton | `frontend-scaffold` (skill) | `skills/frontend-scaffold/` | aktif (dibuat 2026-11-04) |

### MCP servers aktif (dari `~/.config/opencode/opencode.jsonc`)

context7, codegraph, grep_app, github, time, exa, playwright, omnisql, agentmemory, chrome-devtools, ast-grep. **Tidak ada** image-generation MCP (fal/Replicate/OpenAI). Disabled: postgres, mobile-mcp, agy-bridge, app-publish-mcp, figma, mongodb.

### Batasan lingkungan

- Skill `imagegen-*` tinggal di `~/.agents/skills/` — root yang pada audit sebelumnya (H4/H6) ditandai sebagai duplikat usang yang tidak dibaca OpenCode. Mereka AKTIF di sesi ini via harness skill list, tetapi rumah kanoniknya rapuh: kalau direktori itu dibersihkan, skill hilang. **Rekomendasi: pindahkan/mirror ke `~/.config/opencode/skills/`** (root yang pasti dibaca).
- `experimental_image_generate` adalah tool "experimental" — bisa berubah tanpa notice; jangan jadikan satu-satunya jalur produksi.

## Key Findings (bertriangulasi)

### 1. Motion: `motion/react` adalah default yang benar untuk 2026

- **Sumber primer (motion.dev/docs/gsap-vs-motion)**: Motion (dulu Framer Motion) adalah animation library paling terpakai dan tercepat tumbuh — 16 juta download/bulan. Lisensi **MIT irrevocable**, disponsori Framer/Figma/Sanity/Tailwind/LottieFiles. Animasi **hardware-accelerated** (jalan di GPU, tetap 60/120fps bahkan saat JS thread sibuk). Package sekarang `motion` dengan import `motion/react`; `framer-motion` legacy.
- **Sumber independen (Syncfusion, Sep 2026)**: Motion unggul untuk animasi tied-to-component-state, enter/exit transitions, gestures, reusable UI patterns; GSAP unggul untuk timeline choreography, advanced scroll, SVG-heavy.
- **Adversarial (dari sumber yang sama)**: GSAP closed-source, dimiliki Webflow, **dilarang dipakai di tool yang kompetitor Webflow**, dan bisa di-terminate atas kebijakan Webflow. Motion independen → jaminan kebebasan.
- **Kesimpulan**: stack lokal (`motion-foundations` → `-patterns` → `-advanced`) sudah tepat dan current. Tidak ada yang perlu diambil dari internet untuk motion.

### 2. Image generation API: ranking 2026 (jika butuh terprogram)

| Sumber | Temuan |
|---|---|
| APIbenchmarks (Okt 2026) | OpenAI Images 90.5 (A) > Google Imagen/Gemini Image 88.2 (A) > fal.ai 82.6 (B) > Replicate 80.2 (B) > Stability 72.7 > FLUX 67.4 > Ideogram 61.2. Index skor dokumentasi/reliability/ecosystem/accessibility — **bukan kualitas gambar**. Google: reliability terbaik (95), free AI Studio key. fal.ai: accessibility terbaik (88), kredit $20. OpenAI: dokumentasi + ecosystem terbaik, harga sampai $0.25/gambar. |
| Wireflow (Jul 2026) | fal.ai = inferensi tercepat; Replicate = katalog model terbanyak; OpenAI = pemahaman prompt terbaik. |
| aireiter text-rendering test (Agu 2026) | **GPT Image 2 = satu-satunya model 6/6 elemen teks benar** pada UI mockup (header, subtext, field labels, button, footer). Nano Banana 2 = 4/6 (kualitas scene terbaik, drift di teks kecil). Nano Banana Pro = visual paling striking tapi "mengarang" teks kecil. Seedream 5 Pro = 3.5/6. |

**Implikasi untuk use-case frontend design reference:**
- Butuh teks legible di mockup (label, CTA, heading) → **GPT Image 2 / gpt-image (OpenAI)**
- Butuh kecepatan + banyak pilihan model (Nano Banana 2, Seedream, Flux) + gratis mulai → **fal.ai**
- Butuh gratis total untuk eksperimen → **Google AI Studio key** (Imagen/Gemini image)

### 3. Workflow mockup-to-code (kontekstual)

Sumber independen (O2O, Feb 2026): dua pola terbukti — (a) Stitch → HTML → Figma → Framer untuk kualitas + kontrol (4–6 jam); (b) Stitch → Lovable untuk kecepatan validasi (2–3 jam, hasil lebih "generic AI"). Di setup kita, padanan internal: `imagegen-*` (generate reference) → `multimodal-looker` (ekstrak token) → `design-contract-system` (kontrak) → implementasi. Ini setara pola (a) dengan kontrol penuh.

## Adversarial Trade-offs

1. **Kenapa TIDAK langsung pasang fal.ai MCP?** Tool `experimental_image_generate` sudah menghasilkan gambar hari ini. MCP eksternal = API key + biaya + dependensi baru. Tambah HANYA jika: butuh batch terprogram, butuh model spesifik (Nano Banana editing), atau butuh output konsisten di luar sesi agent. Kalau kebutuhan tetap "agent generate saat mendesain", yang ada sudah cukup.
2. **Kenapa tidak GSAP?** Untuk kebutuhan frontend React (dashboard, landing, komponen), Motion menang di setiap axis kecuali scroll-choreography ekstrem. GSAP juga membawa risiko lisensi (larangan kompetitor Webflow, terminasi atas kebijakan).
3. **Risiko root `~/.agents/skills/`**: imagegen-* aktif tapi di root rapuh. Mitigasi murah: mirror ke `~/.config/opencode/skills/`.
4. **Risiko tool experimental**: `experimental_image_generate` bisa berubah; untuk pipeline produksi, simpan hasil generate ke repo (seperti pola `docs/research/` + assets) supaya tidak bergantung pada regenerasi.
5. **`fal-ai-media` skill adalah dead weight** tanpa MCP — biarkan (tidak merugikan) atau konfigurasi MCP-nya; jangan hapus karena dokumentasi model-nya tetap berguna sebagai referensi.

## Katalog Model Image — Fakta Terverifikasi (2026-11-04)

Diperiksa langsung via `tools.opencode.models({type:"image"})`:

- **9router tidak punya model image sama sekali.** Provider itu hanya expose chat: `9router/ag/gemini-3.8-flash-low` dan `9router/ag/gemini-3.8-flash-high`. Tidak ada "gemini 3.1 flash image" di katalog — quota 9router **tidak bisa** dipakai untuk gen image lewat jalur ini.
- **Seluruh katalog image hanya 4 model, semuanya `cloudflare-workers-ai`**: `@cf/black-forest-labs/flux-2-klein-9b` (general/UI reference), `@cf/leonardo/lucid-origin` + `@cf/leonardo/phoenix-1.0` (artistic/illustrative), `@cf/bytedance/stable-diffusion-xl-lightning` (fast drafts).
- **Keputusan owner (2026-11-04)**: pakai default existing — 4 model cloudflare-workers-ai via tool `experimental_image_generate`, tanpa key/biaya baru. Jalur terprogram (fal.ai / OpenAI / Google AI Studio) tetap opsional, hanya jika nanti dibutuhkan.

## Scaffold: Dari Kontrak ke Skeleton

Keputusan owner (2026-11-04): **skill baru `frontend-scaffold`** di `skills/` (kanonik repo, ter-mirror ke `.agents/` + global). Skill itu menjembatani `design-contract-system` (kontrak) → implementasi: baca DESIGN.md + TOKEN-MAP + STATES-MATRIX + page CONTRACT (fail-closed kalau tidak ada), generate struktur project (deteksi Next.js/Vite), wire token verbatim dari THEME.md, generate page shells + komponen state (hanya yang in-scope di kontrak), route image (default cloudflare-workers-ai) + animasi (motion/react untuk in-app, Remotion hanya untuk deliverable video file), lalu audit gate grep kanonik.

## Actionable Recommendation

### Sekarang (tanpa install apa pun)
1. **Image**: pakai skill `imagegen-frontend-web` (atau `-mobile`) untuk arah visual + tool `experimental_image_generate` untuk eksekusi + agent `multimodal-looker` untuk verifikasi hasil. Untuk loop kualitas, pakai command `gan-design`.
2. **Motion**: pakai `motion-foundations` (token/spring/SSR safety) → `motion-patterns` (button/modal/toast/stagger/scroll) → `motion-advanced` (drag/gesture/SVG/imperative). Stack `motion/react`, bukan `framer-motion` legacy.
3. **Mirror imagegen-*** ke `~/.config/opencode/skills/` (satu perintah `cp -r`, hindari kehilangan skill).

### Kalau nanti butuh image API terprogram (opsional, siapkan untuk `/plan`)
4. **Pilihan utama: fal.ai MCP** — tambahkan entry `fal` di `opencode.jsonc` (API key dari fal.ai/dashboard), aktifkan skill `fal-ai-media` yang sudah ada. Alasan: katalog model luas (Nano Banana 2, Seedream 5, Flux), inferensi tercepat, kredit $20 untuk uji.
5. **Pilihan alternatif: OpenAI gpt-image** — kalau prioritas #1 adalah teks legible di mockup UI (satu-satunya 6/6 di test independen).
6. **Eksperimen gratis: Google AI Studio key** — Imagen/Gemini image, reliability terbaik, ada free tier.

### Tidak direkomendasikan
- Pasang GSAP untuk kebutuhan umum frontend React (lisensi + tidak ada keunggulan untuk use-case ini).
- Membuat command motion khusus — motion adalah skill-driven saat implementasi; command akan duplikatif.

## Sumber

- [GSAP vs Motion (motion.dev, official)](https://motion.dev/docs/gsap-vs-motion)
- [Motion vs GSAP in React (Syncfusion, Sep 2026)](https://www.syncfusion.com/blogs/post/motion-vs-gsap-react)
- [Image generation API benchmark 2026 (APIbenchmarks, Okt 2026)](https://apibenchmarks.com/blog/image-generation-api-benchmark-2026)
- [Best Image Generation API for Developers 2026 (Wireflow, Jul 2026)](https://www.wireflow.ai/blog/best-image-generation-api-for-developers-2026)
- [Best AI Image Model for Text Rendering (aireiter, Agu 2026)](https://aireiter.com/blog/best-ai-image-model-text-rendering-2026)
- [Testing AI Workflows: Navigable Prototypes (O2O, Feb 2026)](https://www.o2ods.com/en/blog/testing-ai-workflows-to-create-navigable-prototypes/)

*Catatan: klaim "text rendering 6/6" dan "16M downloads/bulan" bersumber tunggal dari masing-masing artikel test/benchmark — belum diverifikasi silang; treat sebagai indikatif, bukan fakta keras.*
