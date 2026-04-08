[blueprint.md](https://github.com/user-attachments/files/26560109/blueprint.md)
# Project Tanya Ustadz

## Goals :

#### **AhsanTV** secara rutin mengadakan kajian mingguan setiap malam Ahad. setiap sesi ceramah adalah 1 jam lebih 20 menit. Riciannya adalah 1 jam adalah materi dan 20 menit untuk menjawab pertayaan jamaah masjid.

#### Disinilah sebuah ide muncul, Karena keterbatasan waktu maupun pertanyaan-pertanyaan ambigu bagi jamaah yang enggan di ajukan karena akan membuat jemaah tersebut penasaran hingga akhir hayatnya. ****

#### maka hadir lah program “TANYA USTADZ”.  **Program** ini hadir untuk menyelesaikan masalah tersebut sesederhana mungkin dengan hasil semaksimal mungkin dan se-murah mungkin.

### stack :

#### Nuxt.js + Supabase Free Tier

### folder structure ( V3 ) :

```
tanya-ustadz-app/
├── .env                # ADMIN_GATE_PASSWORD, SUPABASE_URL, dll.
├── nuxt.config.ts
├── app.vue
│
├── components/
│   ├── ui/                 # Komponen dasar (Button.vue, Input.vue, Badge.vue)
│   ├── AppHeader.vue       # Header Hijau untuk Jemaah (index.vue)
│   ├── QuestionCard.vue    # Satu komponen untuk semua status (Terjawab/Pending)
│   └── Dashboard/
│       ├── Sidebar.vue     # Sidebar Hijau (dari admin-dashboard.jpg)
│       ├── UserProfile.vue # Widget di pojok kanan atas (dari select-role.jpg)
│       ├── ReplyModal.vue  # Modal input jawaban Ustadz
│       └── StatCard.vue    # Card ringkasan di halaman Archive & Dashboard
│
├── middleware/
│   ├── gate-guard.ts       # Pintu 1: Cek apakah sudah isi Password Gate
│   ├── auth.ts             # Pintu 2: Cek Sesi Google OAuth (Supabase)
│   └── role-guard.ts       # Pintu 3: Cek apakah sudah pilih role (Admin/Ustadz)
│
├── composables/
│   ├── useQuestions.ts     # CRUD, Real-time logic, & Auto-delete 30 hari logic
│   ├── useAdminAuth.ts     # State management untuk simpan role & session Google
│   └── useUI.ts            # State untuk toggle Sidebar atau Modal
│
├── pages/
│   ├── index.vue           # Jemaah: Feed pertanyaan (Tab: Semua, Belum, Terjawab)
│   ├── ask.vue             # Jemaah: Form kirim pertanyaan (dari ask-dot-vue.jpg)
│   ├── success.vue         # Jemaah: Konfirmasi sukses (setelah kirim)
│   │
│   ├── password-page.vue   # Gate 1: Secure Gate (Latar Hijau Tua)
│   ├── login-gate.vue      # Gate 2: Login Google OAuth
│   ├── select-role.vue     # Gate 3: Pilih Admin/Ustadz (dari select-role-dot-vue.jpg)
│   │
│   └── dashboard/          # Folder Khusus Pengelola (Layout: Sidebar)
│       ├── index.vue       # Pusat Moderasi (Admin) / Jawab (Ustadz)
│       ├── archive.vue     # Gudang data & Fitur Pinned (dari admin-dashboard.jpg)
│       └── profile.vue     # Pengaturan & Kontribusi (dari profile-dot-vue.jpg)
│
├── server/
│   └── api/
│       └── verify-gate.post.ts # Validasi password gerbang pertama
│
└── supabase/
└── migrations/
└── setup.sql       # Schema: id, question, answer, category, status, is_pinned, created_at

CaCatatan Implementasi:
- Delete tidak pernah dilakukan dari client
- Semua penghapusan dilakukan oleh:
  - Supabase Edge Function (cron job)
  - atau server dengan service role
```

# flow

### admin :

**Tahap Setup & Akses:**

Akses URL `/admin` -> Masukkan password di **Password Gate** (Pintu 1) -> Klik **Login with Google** (Pintu 2) -> Pilih role **"Admin (Moderator)"** pada halaman Select Role -> Masuk ke Dashboard Admin.

**Jobdesk & Operasional:**

Pantau tab **"Moderasi"** secara *real-time* -> Cek pertanyaan baru yang masuk dari Jamaah -> **Filter Konten:** Jika pertanyaan mengandung spam/SARA/tidak layak, klik **"Tolak"** (Data masuk ke Archive dengan status *Rejected*) -> **Filter Kualitas:** Jika pertanyaan layak dan bagus, klik **"Setujui"** -> Status pertanyaan berubah menjadi `verified` -> Pertanyaan otomatis pindah ke tab **"Perlu Dijawab"** milik Ustadz -> Selesai.

**Manajemen Data:**

Buka tab **"Archive"** -> Pantau riwayat pertanyaan yang sudah disetujui atau ditolak -> Cek indikator **"Hapus dalam X hari"** agar tahu sisa umur data di Supabase -> Logout.

### Poin Kunci untuk Admin:

- **Tanggung Jawab:** Menjadi "satpam" konten agar Ustadz hanya menerima pertanyaan yang berbobot.
- **Otoritas:** Bisa menghapus pertanyaan, tapi **tidak bisa** mengisi jawaban teks (hak akses eksklusif Ustadz).
- **Tools:** Fokus utama hanya pada tombol **Setujui** (Hijau) dan **Tolak** (Merah).

### Ustadz :

**Tahap Akses & Login:**

Akses URL `/admin` -> Masukkan password di **Password Gate** (Pintu 1) -> Klik **Login with Google** (Pintu 2) -> Pilih role **"Ustadz"** pada halaman Select Role -> Masuk ke Dashboard Khusus Ustadz.

**Jobdesk Utama:**

Buka tab **"Perlu Dijawab"** -> Lihat daftar pertanyaan yang sudah lolos filter Admin (Moderator) -> Pilih satu pertanyaan berdasarkan **Upvotes terbanyak** atau urgensi -> Klik tombol **"Balas"** -> Ketik jawaban teks pada kolom yang tersedia -> Klik **"Kirim Jawaban"** -> Selesai.

**Manajemen & Output:**

Pertanyaan otomatis pindah ke status `answered` -> Jawaban langsung muncul secara *real-time* di HP Jamaah (Tab Terjawab) -> Masuk ke tab **"Archive"** jika ingin mengedit atau melihat kembali jawaban yang sudah dikirim sebelumnya -> Logout.

### Poin Kunci untuk Ustadz:

- **Fokus Utama:** Memberikan ilmu dan jawaban, bukan membuang pesan sampah (sudah dibereskan Admin).
- **Hak Akses:** Bisa membaca pertanyaan yang sudah di-`verified` dan menulis teks jawaban.
- **Tampilan:** UI jauh lebih bersih dan tenang (Fokus Mode) agar Ustadz nyaman saat mengetik jawaban panjang.

### Jemaah :

**Tahap Akses & Bertanya:**

Buka URL Utama (Frontend) -> **Tanpa Login** -> Klik tombol **"Tanya Ustadz"** -> Pilih **Kategori/Topik** (Opsional) -> Ketik pertanyaan (Anonim/Hamba Allah) -> Klik **"Kirim"** -> Muncul status: "Menunggu Moderasi".

**Interaksi & Komunitas:**

Buka Tab **"Semua"** -> Lihat daftar pertanyaan dari jamaah lain -> Klik **"Upvote" (Icon Love)** pada pertanyaan yang dirasa penting/mewakili (agar naik ke urutan atas untuk Ustadz) -> Gunakan fitur **Cari** untuk melihat topik yang mirip.

**Menerima Jawaban:**

Buka Tab **"Terjawab"** -> Cari pertanyaan sendiri (Berdasarkan ID Hamba Allah/Waktu) -> Baca jawaban teks dari Ustadz -> **Simpan/Screenshot** jawaban (Karena data akan otomatis Terhapus dalam 30 Hari)-> Selesai.

### Poin Kunci untuk User:

- **Privasi:** Aman 100% karena tidak ada pengumpulan data pribadi atau akun Google.
- **Sistem Upvote:** User punya kekuatan kolektif untuk menentukan pertanyaan mana yang harus segera dijawab Ustadz.
- **Self-Clean:** User harus sadar bahwa forum ini bersifat sementara (30 hari), sehingga mereka harus rajin mengecek jawaban sebelum hilang.

# Pages

### Group 1: Public Pages (Jamaah)

Halaman yang bisa diakses siapa saja tanpa login. Fokus pada kecepatan dan kemudahan bertanya.

- **`index.vue` (Halaman Utama / Beranda)**
    - **Visual:** Daftar pertanyaan terbaru dengan tab "Semua", "Terjawab", dan "Trending" (berdasarkan upvotes).
    - **Fitur:** Tombol "Tanya Ustadz" (Floating Action Button), sistem Upvote, dan Search bar.
    
    Search Behavior:
    
    - Gunakan debounce 300ms
    - Normalize input (lowercase + trim)
- **`ask.vue` (Formulir Bertanya)**
    - **Visual:** Input teks sederhana (maksimal 4 baris), pilihan kategori, dan tombol kirim anonim.
    - Rate Limit:
    
    1 fingerprint hanya boleh kirim 1 pertanyaan per 5 menit
    
- **`success.vue` (Konfirmasi Berhasil)**
    - **Visual:** Pesan terima kasih dan pengingat bahwa pertanyaan akan dimoderasi dalam waktu dekat.
    
    Prevent Double Submit:
    
    - Disable tombol submit saat request sedang berjalan

### Group 2: Access Gate (Pintu Masuk Admin)

Halaman transisi sebelum masuk ke dashboard rahasia.

- **`login-gate.vue` (Password Gate - Pintu 1)**
    - **Visual:** Minimalis, hanya satu kolom input password "Rahasia Lingkungan" untuk memproteksi halaman login Google.
- **`select-role.vue` (Pilihan Role - Pintu 2)**
    - **Visual:** Muncul setelah Google OAuth berhasil. Dua kartu besar: **"Masuk sebagai Admin"** atau **"Masuk sebagai Ustadz"**.

### Group 3: Dashboard Pages (Terproteksi)

Halaman khusus pengelola dengan tampilan dinamis berdasarkan role yang dipilih.

- **`dashboard/index.vue` (Pusat Kendali)**
    - **Visual Admin:** Daftar kartu pertanyaan "Pending" dengan tombol **Setujui** (Hijau) & **Tolak** (Merah).
    - **Visual Ustadz:** Daftar kartu pertanyaan "Verified" dengan tombol **Balas** (Hijau).
- **`dashboard/archive.vue` (Gudang Data 30 Hari)**
    - **Visual:** Tabel atau list riwayat pertanyaan yang sudah selesai (Terjawab/Ditolak).
    - **Fitur:** Tombol **"Pin"** untuk menyimpan pertanyaan selamanya (melewati batas 30 hari).
- **`dashboard/profile.vue` (Info Akun)**
    - **Visual:** Menampilkan email Google yang aktif dan tombol Logout.

# Kategori Pertanyaan :

#### **Fikih:** (Ibadah, Shalat, Puasa, dll)

#### **Akhlak & Adab:** (Perilaku sehari-hari)

#### **Keluarga:** (Pernikahan, Parenting, Waris)

#### **Muamalah:** (Ekonomi, Jual Beli, Kerja)

#### **Umum:** (Pertanyaan di luar kategori atas)

# SUPABASE QUERIES

### 1. questions

```sql
create table questions (
  id uuid default gen_random_uuid() primary key, --Ticket ID: - Gunakan 4 digit terakhir UUID - Format: #TU-XXXX - Generate di backend
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  question text not null,
  category text,
	  status text default 'pending', -- pending, verified, rejected, answered
  answer text,
  is_pinned boolean default false,
  upvotes int default 0
);
-- upvotes harus dihitung dari count(question_votes)
-- atau gunakan trigger untuk sync otomatis

-- TABLE: question_votes (ANTI-SPAM UPVOTE)
create table question_votes (
  id uuid default gen_random_uuid() primary key,
  question_id uuid references questions(id) on delete cascade,
  fingerprint text not null,
  created_at timestamp with time zone default now(),
  unique(question_id, fingerprint)
);
```

### 2.  Setup Security & Profiles

```sql
-- 1. AKTIFKAN KEAMANAN (RLS) UNTUK TABEL QUESTIONS
alter table questions enable row level security;

-- ADMIN: hanya bisa approve / reject
create policy "Admin can verify or reject"
on questions
for update
using (
  exists (
    select 1 from profiles
    where profiles.id = auth.uid()
    and profiles.role = 'admin'
  )
  AND status != 'answered'
)
with check (
  status in ('verified', 'rejected')
);

-- USTADZ: hanya bisa jawab
create policy "Ustadz can answer"
on questions
for update
using (
  exists (
    select 1 from profiles
    where profiles.id = auth.uid()
    and profiles.role = 'ustadz'
  )
)
with check (
  status = 'answered'
);

-- INSERT handled by server (service role)
-- RLS tetap ketat untuk client
create policy "Public can insert questions"
on public.questions
for insert
to anon
with check (true);
-- NOTE:
-- Insert dilakukan via server API menggunakan service role key
-- agar tidak terblokir RLS di production

-- Kebijakan: Semua orang bisa melihat pertanyaan
create policy "Allow select answered only"
on questions
for select
using (status = 'answered');

-- 2. BUAT TABEL PROFIL (UNTUK DATA LOGIN GOOGLE)
create table profiles (
  id uuid references auth.users on delete cascade primary key,
  full_name text,
  email text,
  avatar_url text,
  role text check (role in ('admin', 'ustadz')) default null
);

-- 3. FUNGSI OTOMATIS: PINDAHKAN DATA GOOGLE KE TABEL PROFIL
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, email, avatar_url)
  values (
    new.id, 
    new.raw_user_meta_data->>'full_name', 
    new.email, 
    new.raw_user_meta_data->>'avatar_url'
  );
  return new;
end;
$$ language plpgsql security definer;

-- 4. TRIGGER: JALANKAN FUNGSI DI ATAS SETIAP ADA USER BARU DAFTAR/LOGIN
create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
```

## **Catatan Teknis Role:**

- Secara default, kolom `role` di tabel `profiles` adalah `NULL`.
- Halaman `select-role.vue` bertugas melakukan `UPDATE` pada kolom `role` di tabel `profiles` sesuai pilihan user (Admin/Ustadz).
- Setelah role terpilih, simpan status tersebut di `useAdminAuth.ts` (Pinia/Composable) agar Dashboard bisa menyesuaikan tampilan secara realtime.

## RLS Detail per Role

Catatan Penting:

- Walaupun RLS tetap didefinisikan di database, semua operasi utama dilakukan melalui server menggunakan Service Role Key
- RLS berfungsi sebagai fallback security layer, bukan mekanisme utama

Catatan Implementasi:

- Semua operasi utama (insert, update, delete) dilakukan melalui server API menggunakan Service Role Key
- RLS tetap digunakan sebagai lapisan keamanan tambahan (fallback), bukan mekanisme utama

# **Technical Specs** atau **Development Rules**

> **Objective:** Maintain high consistency between visual mockups, database integrity, and multi-layered security.
> 

### 1. State Management & Authentication Flow

- **Gate 1 Persistence:** Store the successful entry of `password-page.vue` in a secure cookie (`gate_access: true`) with a 24-hour expiration. Prevent users from re-entering the password on every refresh.
- **Role-Based Access Control (RBAC):** * After Google OAuth, fetch the user's role from the `public.profiles` table.
    - If `role` is `null`, force redirect to `select-role.vue`.
    - Protect all `/dashboard/**` routes using `middleware/auth.ts` and `middleware/role-guard.ts`.
- **Auth State UI:** The `UserProfile.vue` component must reactively display `user.user_metadata.full_name` and `avatar_url` from the Supabase auth session.

### 2. Database Logic & Query Rules

- **The "30-Day Cleanup" Logic:** * Do NOT perform hard deletes on the client-side. MANDATORY: Use Supabase Edge Function + Cron Job.
    - **Filtering Rule:** When fetching questions for `index.vue` (Jemaah), apply a filter: `WHERE status = 'answered’`.
    - **Pinned Exception:** Any record where `is_pinned = true` must be exempted from all age-based filtering/deletion logic.
- **Real-time Subscription:** Use Supabase `REALTIME` to listen for `INSERT` events on the `questions` table. When a new question is detected, trigger a toast notification or a list refresh in the Admin Dashboard. Admin: listen INSERT (pending), Ustadz: listen UPDATE (status = verified), Jemaah: listen UPDATE (status = answered)

### 3. UI/UX Consistency Rules

- **The Emerald Theme:** strictly use Tailwind's `emerald` palette.
    - `primary`: `emerald-600`
    - `dark-gate`: `emerald-900` (for `password-page.vue`)
    - `amber-pending`: `amber-50` (background) and `amber-600` (text/border) for pending question cards.
- **Responsive Strategy:** * **Jemaah Pages:** Center-aligned, maximum width `max-w-md` (Mobile-focused).
    - **Admin Dashboard:** Full-width liquid layout with a fixed sidebar (Desktop-focused).
- **Loading States:** Implement `v-if="pending"` skeletons for `QuestionCard.vue` to prevent layout shift during Supabase data fetching.

### 4. Component Requirements

- **`QuestionCard.vue` Props:** Must accept a `mode` prop (`'jemaah' | 'admin' | 'ustadz'`).
    - `jemaah`: Displays only the question and answer.
    - `admin`: Displays moderation buttons (Approve/Reject/Delete).
    - `ustadz`: Displays the "Answer" button/modal trigger.
    
    IMPORTANT :
    
    - jangan handle semua action dalam 1 file
    - Gunakan sub-component :
        - AdminAction.vue
        - UstadzReply.vue
- **`ReplyModal.vue`:** Use a simple `textarea` with a character counter. Ensure the `Update` query specifically targets the `answer` and `status` columns. Validation : Pastikan data masih exist sebelum submit (handle case data sudah dihapus oleh cron job)

### 5. Error Handling

- **Auth Errors:** If a user logs in with a non-authorized Google account, clear the session and redirect to `login-gate.vue` with an error message: *"Akses Terbatas: Gunakan akun pengelola yang terdaftar."*
- **Empty States:** If a tab (e.g., 'Belum Dijawab') has no data, display the "Empty State" illustration as defined in the visual mockups.

# Final Checklist: The Last 5% (Production & Deployment Rules)

> **Objective:** Ensure the application is secure, professional, and ready for production deployment.
> 

### 1. Environment & Security Hardening

- **Zero-Leak Policy:** Ensure `.env` is strictly added to `.gitignore`. Do not hardcode any Supabase or Google Client keys in the source code.
- **Production Secret Management:** For deployment (Vercel/Netlify), use the platform's Environment Variables dashboard to inject `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `GOOGLE_CLIENT_ID`, and `ADMIN_GATE_PASSWORD`.
- **Cookie Security:** Configure the `gate_access` cookie with `HttpOnly` (if using server-side validation) and `SameSite: Strict` to prevent CSRF.

### 2. Data Integrity & Input Validation

- **Character Limits:** Implement strict `maxlength` validation on both Frontend (UI) and Backend (Supabase RLS/Check Constraints):
    - **Questions:** Maximum 500 characters.
    - **Answers:** Maximum 2000 characters.
- **Sanitization:** Ensure all user-generated content (questions/answers) is sanitized to prevent XSS (Cross-Site Scripting) when rendered in the feed.

### 3. SEO & Branding (Nuxt Config)

- **Metadata Configuration:** In `nuxt.config.ts`, set up the `app.head` object:
    - **Title Template:** Use a dynamic title like `%s | Tanya Ustadz V3`.
    - **Favicon:** Link to `/favicon.ico` (ensure the logo-final.jpg is converted and placed in the `public/` folder).
    - **Meta Tags:** Add essential OpenGraph tags (title, description, image) for professional link sharing on social media/WhatsApp.

### 4. UX Polishing

- **Empty States:** Create a reusable `EmptyState.vue` component to show when a category or tab has zero questions.
- **Toast Notifications:** Implement a global notification system (e.g., `vue-sonner` or a custom composable) to give feedback for:
    - Success: *"Pertanyaan terkirim!"*
    - Success: *"Jawaban berhasil disimpan!"*
    - Error: *"Login gagal. Silakan coba lagi."*

### 5. Deployment Strategy

- **Target Platform:** Optimize for **Vercel** or **Netlify** deployment.
- **Build Command:** Ensure `npm run build` executes without TypeScript errors or linting warnings.

# NOTES FOR CLAUDE  FINAL HARDENING (MANDATORY RULES)

## 1. Final Status Enum (STRICT)

Gunakan hanya 4 status berikut dan **tidak boleh membuat variasi lain**:

- `pending` → default dari jemaah
- `verified` → sudah disetujui admin
- `rejected` → ditolak admin (tidak muncul di public)
- `answered` → sudah dijawab ustadz

### Database Constraint (WAJIB)

```sql
alter table questions
add constraint valid_status check (
  status in ('pending', 'verified', 'rejected', 'answered')
);
```

---

## 2. Role-Based Access Control (STRICT RLS)

### Public (Jemaah)

- INSERT: allowed

INSERT: Boleh (tanpa login)

Catatan Implementasi:

- Request dilakukan melalui server API (`/api/questions`)
- Server menggunakan Supabase Service Role Key (bypass RLS)
- Validasi tetap dilakukan di server:
    - Rate limit (1 pertanyaan / 5 menit / fingerprint)
    - Validasi panjang teks
    - Sanitasi input (XSS protection)

Implementasi:

- Insert tidak dilakukan langsung dari client ke database
- Semua request masuk melalui server API (/api/questions)
- Server menggunakan Service Role Key untuk menghindari konflik RLS
- SELECT: hanya `status = 'answered'`

Catatan Implementasi:

- Jemaah (public) hanya mengambil data dengan status 'answered'
- Admin & Ustadz mengambil semua data melalui server (service role / function)
- Realtime subscription tetap mengikuti scope role masing-masing

### Admin (role = 'admin')

- Hanya boleh:
    - update `status` → `verified` atau `rejected`
        
        Catatan Implementasi:
        
        - Semua update dilakukan melalui server API:
            - `/api/admin/moderate`
            - `/api/admin/pin`
            - `/api/ustadz/answer`
        - Server menggunakan Service Role Key
        - Validasi role tetap dilakukan di server (bukan hanya RLS)
- Tidak boleh:
    - mengisi `answer`

### Ustadz (role = 'ustadz')

- Hanya boleh:
    - update `answer`
        
        Catatan Implementasi:
        
        - Semua update dilakukan melalui server API:
            - `/api/admin/moderate`
            - `/api/admin/pin`
            - `/api/ustadz/answer`
        - Server menggunakan Service Role Key
        - Validasi role tetap dilakukan di server (bukan hanya RLS)
        - Semua proses dilakukan melalui server API, bukan langsung dari client
    - set `status` → `answered`
- Tidak boleh:
    - approve / reject

### ⚠️ IMPORTANT

Gunakan **column-level restriction**, bukan hanya role check global.

---

## 3. Upvote System (ANTI-SPAM LIGHT)

### Table tambahan:

```sql
question_votes:
- id
- question_id
- fingerprint
```

### Fingerprint Definition:

Gabungan dari:

- IP Address
- User Agent
- Random UUID dari localStorage

### Rules:

- 1 fingerprint hanya boleh vote 1x per question
- Tolak insert jika sudah pernah vote

---

## 4. Auto Delete System (EDGE FUNCTION + CRON)

### WAJIB:

Gunakan Supabase Edge Function + Cron Job

### Logic:

Jalankan setiap hari (00:00):

```sql
delete from questions
where
  is_pinned = false
  and created_at < now() - interval '30 days';
```

### ⚠️ Constraint:

- `is_pinned = true` → tidak boleh dihapus
- Tidak boleh implementasi delete di client-side

---

## 5. Gate Password Security (SERVER-ONLY)

### Rules:

- Password disimpan di `.env`
- Validasi via `server/api/verify-gate.post.ts`
- Tidak boleh expose password ke client

### Rate Limit:

- Max 5 request gagal / IP / 15 menit

### Additional Protection:

- Tambahkan delay 500ms untuk setiap gagal login

---

## 6. Search System (SIMPLE + OPTIMIZED)

Gunakan query:

```sql
ilike '%keyword%'
```

### Kolom:

- question
- category

### Frontend Rules:

- lowercase input
- trim whitespace
- debounce 300ms

---

## 7. Anonymous Identity (Ticket ID)

### Format:

```
#TU-XXXX
```

### Rules:

- XXXX = 4 digit terakhir dari UUID
- Generate di server/database layer (BUKAN frontend)
- Ditampilkan di UI untuk membantu pencarian

---

## 8. Rate Limiting (ANTI-SPAM CORE)

### Ask Question:

- Max 1 pertanyaan / 5 menit / fingerprint

### Combine:

- IP + fingerprint

---

## 9. Role Selection Enforcement

### Rules:

Jika:

- user sudah login
- tetapi `profiles.role IS NULL`

Maka:

→ WAJIB redirect ke `/select-role`

### Constraint:

- Semua route `/dashboard/**` harus diblok sebelum role dipilih

---

## 10. Component Architecture (ANTI-BLOAT)

### QuestionCard.vue

WAJIB hanya sebagai wrapper UI

### Action dipisah:

- `AdminAction.vue`
- `UstadzReply.vue`

Gunakan conditional rendering, jangan campur semua logic dalam 1 file

---

## 11. Double Submit Protection

### Problem:

User bisa klik tombol submit berkali-kali

### Solution:

- Disable button saat loading
- Gunakan state `isSubmitting`

---

## 12. Realtime Scope Optimization

### Admin:

- Listen: INSERT (pending)

### Ustadz:

- Listen: UPDATE → verified

### Jemaah:

- Listen: UPDATE → answered

### ⚠️ Jangan subscribe semua event ke semua role

---

## 13. Critical Edge Case Handling

### Case 1:

Ustadz buka modal → data sudah dihapus cron

→ Validasi ulang sebelum submit

### Case 2:

Admin approve → Ustadz masih lihat data lama

→ Refresh / reactive update

### Case 3:

Vote spam

→ Sudah ditangani oleh fingerprint system

---

## 14. Data Integrity Protection

### WAJIB:

- Question max: 500 char
- Answer max: 2000 char

### Sanitization:

- Escape HTML untuk mencegah XSS

---

## 15. Ticket Consistency Rule

Ticket ID:

- Harus konsisten
- Tidak boleh berubah
- Tidak boleh generate ulang di frontend

---

# 🔥 FINAL DIRECTIVE FOR CLAUDE

- Jangan membuat asumsi di luar dokumen ini
- Jangan menambahkan fitur di luar scope
- Fokus pada:
    - security
    - consistency
    - simplicity
- Semua logic harus deterministic dan predictable
