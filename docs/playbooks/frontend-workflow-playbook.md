# Frontend Workflow Playbook for Nexvora (ECC + OpenCode)

> **Tujuan**: Panduan eksekusi deterministik untuk mengubah UI web menjadi kelas enterprise yang estetik, stabil, dan bebas *AI-slop*, khusus menggunakan skill dan slash command yang sudah terpasang global di laptop ini.

---

## Daftar Isi
1. [Prinsip Inti Anti-Slop](#1-prinsip-inti-anti-slop)
2. [Fast-Path Decision Matrix (< 2 Menit)](#2-fast-path-decision-matrix--2-menit)
3. [Case A: Anti-Slop Elevation (UI Sudah Jadi tapi Terlihat Generik/AI)](#case-a-anti-slop-elevation-ui-sudah-jadi-tapi-terlihat-generikai)
4. [Case B: Enterprise Data Density (Tabel Kompleks, Filter, Dashboard)](#case-b-enterprise-data-density-tabel-kompleks-filter-dashboard)
5. [Case C: Accessibility & Multi-Viewport Hardening (Responsif & A11y)](#case-c-accessibility--multi-viewport-hardening-responsif--a11y)
6. [Case D: Micro-Interactions & Subdued Motion (Animasi Halus & Responsif)](#case-d-micro-interactions--subdued-motion-animasi-halus--responsif)
7. [Case E: Design Token Harmonization (Konsistensi Spasi, Radius, & Warna)](#case-e-design-token-harmonization-konsistensi-spasi-radius--warna)
8. [Protokol Render-Gate (Wajib Sebelum Commit)](#8-protokol-render-gate-wajib-sebelum-commit)
9. [Daftar Pantangan (Anti-Pattern Catalog)](#9-daftar-pantangan-anti-pattern-catalog)

---

## 1. Prinsip Inti Anti-Slop

1. **Audit Terlebih Dahulu, Jangan Langsung Rewrite**: AI cenderung merombak ulang seluruh file jika diminta "perbaiki UI". Selalu kunci temuan masalah visual spesifik sebelum menyentuh kode.
2. **"Source Inspection Alone Cannot Pass"**: Kode bersih di editor tidak menjamin UI tidak pecah di browser. Verifikasi visual berbasis browser/viewport adalah gerbang mutlak.
3. **One Primary Visual Owner**: Gunakan `frontend-ui-ux` untuk memegang arah layout utama, dan gunakan `impeccable-style` atau `make-interfaces-feel-better` hanya sebagai lapisan polish detail di akhir.
4. **Haram Menggunakan `/gan-design` untuk UI yang Sudah Jadi**: `/gan-design` membangun dari nol secara acak dan berisiko merusak struktur komponen yang sudah bekerja.

---

## 2. Fast-Path Decision Matrix (< 2 Menit)

| Gejala Masalah pada UI | Kasus yang Cocok | Urutan Fase Ringkas | Skill / Command Utama |
|---|---|---|---|
| Tampilan kaku, gradien ungu-biru murahan, card di dalam card, terasa buatan AI | **Case A** | Audit Slop → Arah Desain → Plan Canvas → Polish | `design-system` (Mode 3), `frontend-design-direction`, `/plan-canvas`, `make-interfaces-feel-better` |
| Tabel data memanjang, dashboard sesak, filter bertumpuk, DOM lag saat scroll | **Case B** | Data Audit → Layout Density → State Model → TDD | `frontend-patterns`, `senior-frontend`, `click-path-audit`, `/tdd` |
| UI pecah di mobile, teks overlap, fokus keyboard hilang, kontras warna redup | **Case C** | A11y Scan → Viewport Stress → Fix → Browser QA | `a11y-audit`, `accessibility`, `browser-qa` |
| Halaman terasa mati/kaku atau sebaliknya animasi berlebihan bikin pusing | **Case D** | Token Motion → Pattern Component → Frame Budget | `motion-foundations`, `motion-patterns`, `make-interfaces-feel-better` |
| Border radius tidak seragam, warna abu-abu belang, padding acak-acakan | **Case E** | Token Extraction → Rhythm Alignment → Refactor | `design-system` (Mode 1 & 2), `/refactor-clean` |

---

## Case A: Anti-Slop Elevation (UI Sudah Jadi tapi Terlihat Generik/AI)

**Kapan digunakan**: Halaman atau komponen sudah berfungsi penuh, tetapi tampilannya seperti template gratisan AI (background gradient ungu, rounded corner acak, tipografi hambar).

### Alur Fase Eksekusi:

```
[Fase 1: Audit Slop] ──> [Fase 2: Tentukan Arah] ──> [Fase 3: Visual Approval] ──> [Fase 4: Bedah Polish] ──> [Fase 5: Render Gate]
```

#### Fase 1: Audit AI-Slop (Tanpa Edit Kode)
- **Skill**: `design-system` (Mode 3: AI Slop Detection)
- **Instruksi ke Agent**:
  > "Gunakan skill `design-system` Mode 3 untuk memeriksa file [path/ke/Komponen.tsx]. Cari sinyal generic gradient, card-in-card nesting, centered text over stock gradient, dan font sans generik. Laporkan file:line tanpa mengubah kode."
- **Stop Condition**: Dihasilkan daftar temuan konkret visual slop.

#### Fase 2: Tetapkan 5 Keputusan Arah Desain
- **Skill**: `frontend-design-direction`
- **Instruksi ke Agent**:
  > "Gunakan skill `frontend-design-direction`. Tentukan 5 keputusan untuk halaman ini: Purpose, Target Audience, Tone (pilih: utilitarian/refined/dense/calm), 1 Memorable Detail, dan Constraints. Tetapkan 6 content states wajib (loading, empty, error, partial, success, permission)."

#### Fase 3: Rencana & Visual Approval
- **Command**: `/plan` lalu buka `/plan-canvas`
- **Langkah**:
  1. Jalankan `/plan "Refactor visual komponen [nama] berdasarkan audit slop"`
  2. Buka `plan-canvas` untuk memeriksa rencana dekomposisi secara visual sebelum eksekusi dimulai.

#### Fase 4: Eksekusi Polish Detail
- **Skill**: `make-interfaces-feel-better` & `impeccable-style`
- **Aturan Eksekusi**:
  - Ganti warna flat/abu-abu generik dengan token palette yang berkarakter.
  - Terapkan *Concentric Radius* (radius anak = radius kontainer - padding).
  - Pastikan *Optical Alignment* pada ikon dan teks tombol.
  - Terapkan bayangan halus berlapis (*diffused multi-layer shadows*), buang drop-shadow pekat.
  - *Hook otomatis aktif*: Plugin `design-quality-check` akan memvalidasi apakah ada string CTA generik atau grid usang yang tertinggal.

#### Fase 5: Rendered Finish Gate
- **Tool / Script**: `browser-qa` & Chrome DevTools MCP
- **Instruksi**: Buka halaman di browser lokal via Playwright/DevTools, verifikasi screenshot pada viewport 390px dan 1440px.

---

## Case B: Enterprise Data Density (Tabel Kompleks, Filter, Dashboard)

**Kapan digunakan**: Membangun atau merapikan layar kerja utama Nexvora (data table dengan 10+ kolom, multi-filter dropdown, pagination, inline editing, batch actions).

### Alur Fase Eksekusi:

#### Fase 1: Pemetaan State & Interactive Flows
- **Skill**: `click-path-audit`
- **Tujuan**: Memastikan aksi filter, sort, search, dan pagination tidak saling membatalkan state atau menyebabkan race condition.
- **Instruksi ke Agent**:
  > "Gunakan skill `click-path-audit`. Petakan state lifecycle untuk alur filter -> sort -> select all -> batch action pada [komponen tabel]. Cari potensi conflict state."

#### Fase 2: Arsitektur Komponen & Virtualisasi
- **Skill**: `frontend-patterns` & `senior-frontend`
- **Aturan Desain Enterprise**:
  - **Information Density**: Gunakan compact row heights (36px–40px), font monospaced tabular untuk angka (`font-mono tabular-nums`).
  - **Sticky Headers & Action Columns**: Kolom aksi dan header tabel wajib tetap terlihat saat scroll horizontal/vertikal.
  - **Batch State Bar**: Munculkan floating action bar ketika checkbox dipilih, jangan geser layout utama.
  - **Zero Layout Shift**: Berikan fixed min-height pada kontainer tabel selama loading skeleton.

#### Fase 3: Eksekusi TDD untuk State Manipulasi Data
- **Command**: `/tdd`
- **Langkah**: Tulis unit/integration test terlebih dahulu untuk logic sorting, multi-column filtering, dan pagination slice sebelum styling akhir diaplikasikan.

#### Fase 4: Validasi Interaksi Nyata
- **Skill**: `browser-qa`
- **Instruksi**: Gunakan MCP `playwright` untuk mensimulasikan pengetikan pencarian cepat, pemilihan 100 baris, dan verifikasi memori/DOM responsiveness.

---

## Case C: Accessibility & Multi-Viewport Hardening (Responsif & A11y)

**Kapan digunakan**: Mempersiapkan rilis produksi agar UI ramah keyboard, lolos uji kontras WCAG 2.2 AA, dan tidak pecah dari layar iPhone SE hingga monitor 4K Ultrawide.

### Alur Fase Eksekusi:

#### Fase 1: Scanning Otomatis A11y
- **Skill**: `a11y-audit` & `accessibility`
- **Instruksi ke Agent**:
  > "Gunakan skill `a11y-audit` untuk memeriksa komponen [nama]. Periksa rasio kontras teks (minimal 4.5:1 untuk normal, 3:1 untuk large), visible focus ring pada elemen interaktif, dan label ARIA pada icon-only buttons."

#### Fase 2: Viewport Stress Testing
- **Viewport Target**:
  - Mobile: `390x844` (iPhone standard) & `320x568` (narrow mobile baseline)
  - Tablet: `820x1180` (iPad Air portrait)
  - Desktop: `1440x900` (MacBook standard) & `1920x1080` (FHD monitor)
- **Aturan CSS Hardening**:
  - Hindari horizontal overflow (`overflow-x: hidden` di body adalah masking, bukan solusi).
  - Teks panjang harus memiliki kebijakan wrapping yang rapi (`truncate` dengan tooltip atau `break-words`).
  - Target sentuh mobile minimal 44x44px.

#### Fase 3: Keyboard Navigation & Focus Trap Audit
- **Pemeriksaan Wajib**:
  - Modal dialog harus menjebak fokus (*focus trap*) dan mengembalikan fokus ke tombol pemanggil saat ditutup via `Escape`.
  - Dropdown harus dapat dinavigasi dengan tombol panah atas/bawah, `Enter`, dan `Escape`.
  - Semua focus indicator menggunakan ring yang kontras (`ring-2 ring-offset-2`).

#### Fase 4: Automated Gate
- **Tool**: `browser-qa`
- **Output**: Laporan audit otomatis axe-core dan status **SHIP / DO-NOT-SHIP**.

---

## Case D: Micro-Interactions & Subdued Motion (Animasi Halus & Responsif)

**Kapan digunakan**: Menambahkan feedback visual interaktif pada tombol, modal transitions, toast alert, drawer sliding, atau skeleton loading tanpa membuat aplikasi lambat.

### Alur Fase Eksekusi:

#### Fase 1: Fondasi Token Motion (Wajib Pertama)
- **Skill**: `motion-foundations`
- **Aturan Emas**:
  - Durasi micro-interactions: **150ms – 250ms**. Di atas 300ms terasa lambat bagi aplikasi enterprise.
  - Menggunakan spring presets yang terukur (damping tinggi, bounce rendah) bukan kurva cubic-bezier lambat.
  - Wajib membungkus semua animasi dengan query `prefers-reduced-motion: reduce`.

#### Fase 2: Penerapan Pola Interaksi
- **Skill**: `motion-patterns`
- **Checklist Pola**:
  - **Button Click**: Feedback scale mikro (misal `active:scale-[0.98]`), bukan animasi membal besar.
  - **Modal / Dialog**: Fade-in 150ms + scale up halus dari 0.98 ke 1.0. Jangan slide dari luar layar.
  - **Toast Notifications**: Slide-in dari pojok 200ms dengan exit collapse height.
  - **List Enter**: Staggered fade mikro (maksimal 30ms antar item, maksimal 5 item pertama saja).

#### Fase 3: Detail Sentuhan Visual
- **Skill**: `make-interfaces-feel-better` (Section: Motion & Transition Scope)
- **Aturan**:
  - Hanya animasikan properti yang ramah GPU (`transform`, `opacity`).
  - Jangan pernah menganimasikan `width`, `height`, `padding`, atau `margin` karena memicu CPU layout reflow.

---

## Case E: Design Token Harmonization (Konsistensi Spasi, Radius, & Warna)

**Kapan digunakan**: Halaman terdiri dari komponen yang dibuat di waktu berbeda sehingga memiliki 5 jenis warna border abu-abu yang berbeda, variasi padding 13px/15px/18px, dan border-radius tidak teratur.

### Alur Fase Eksekusi:

#### Fase 1: Ekstraksi Token Eksisting
- **Skill**: `design-system` (Mode 1: Generate & Extract)
- **Instruksi ke Agent**:
  > "Gunakan skill `design-system` Mode 1 untuk memindai CSS/Tailwind pada folder komponen. Ekstraksi semua penggunaan warna, spasi, dan radius yang ada ke dalam daftar audit."

#### Fase 2: Visual Consistency Scoring
- **Skill**: `design-system` (Mode 2: Visual Audit)
- **Target**: Dapatkan evaluasi 10 dimensi visual consistency dengan skor 0–10. Fokus pada perbaikan dimensi:
  1. *Color consistency* (reduksi palette abu-abu ke 1 skala netral)
  2. *Spacing rhythm* (kunci ke skala berbasis 4px: 4, 8, 12, 16, 24, 32, 48px)
  3. *Border radius rhythm* (kunci skala: 4px sm, 8px md, 12px lg, 16px xl)

#### Fase 3: Refactoring Terkendali
- **Command**: `/refactor-clean`
- **Instruksi**:
  > "Lakukan substitusi class hardcoded dengan utility tokens Tailwind yang sudah distandarisasi tanpa mengubah hierarki DOM atau binding props."

---

## 8. Protokol Render-Gate (Wajib Sebelum Commit)

Sebelum membuat Pull Request atau melakukan commit perubahan frontend, jalankan urutan gerbang berikut:

1. **Jalankan Verifikasi Browser Lokal**:
   - Pastikan dev server berjalan.
   - Panggil MCP `chrome-devtools` atau `playwright` untuk mengambil snapshot visual.
2. **Cek Bukti Render**:
   - Pastikan 6 kondisi state (`loading`, `empty`, `error`, `partial`, `success`, `permission`) telah diverifikasi.
   - Jalankan validator evidence jika tersedia:
     ```bash
     node ~/.config/opencode/skills/frontend-design-direction/scripts/check-evidence.js report.json
     ```
3. **Double Review Adversarial**:
   - Jalankan `/santa-loop` untuk meminta dua evaluator independen meninjau diff secara terpisah.
   - Atau panggil `/code-review` untuk verifikasi regresi clean code.

---

## 9. Daftar Pantangan (Anti-Pattern Catalog)

| Pantangan (AI-Slop) | Solusi Enterprise Nexvora |
|---|---|
| **Purple/Indigo Default Gradients** pada background hero | Gunakan solid background netral (`bg-slate-900` atau `bg-zinc-50`) dengan aksen warna brand yang presisi dan kontras |
| **Card di dalam Card berulang-ulang** | Gunakan pemisah garis halus (`border-t border-slate-200/80`) atau whitespace rhythm tanpa border berlebih |
| **Penuh Drop-Shadow Hitam Pekat** | Gunakan border tipis 1px (`border border-slate-200/60 dark:border-slate-800`) dipadu multi-stop shadow transparan |
| **CTA Generik Bertebaran** ("Get Started", "Learn More" di tiap sudut) | Berikan label tombol yang action-oriented ("Create Pipeline", "Connect Cluster", "Export CSV") |
| **Marketing Copy di Layar Aplikasi Kerja** | Layar kerja/dashboard harus mengutamakan utilitas dan densitas data, bukan jargon promosi |
| **Animasi Lambat (> 300ms) pada Menu/Dropdown** | Kunci transisi instan atau micro-spring 150ms agar aplikasi terasa cepat |
| **Bypass Review via `git commit --no-verify`** | Dilarang keras. Biarkan hook commit quality dan linter memastikan integritas kode |
