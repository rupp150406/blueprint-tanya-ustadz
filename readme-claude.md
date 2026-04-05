# 🕌 Tanya Ustadz — AhsanTV

Platform tanya-jawab islami antara jamaah dan ustadz AhsanTV. Jamaah dapat mengajukan pertanyaan secara anonim, admin memoderasi, dan ustadz menjawab secara real-time.

**Stack:** Nuxt 3 · Supabase · Tailwind CSS (Emerald) · Pinia · Vue Sonner

---

## 📁 Folder Structure

```
tanya-ustadz-app/
├── .env.example
├── .gitignore
├── nuxt.config.ts
├── tailwind.config.ts
├── app.vue
├── error.vue
│
├── types/
│   └── index.ts                    # Shared TypeScript interfaces
│
├── assets/css/
│   └── main.css                    # Tailwind base + global styles
│
├── supabase/
│   ├── migrations/
│   │   └── setup.sql               # Full schema + RLS + triggers + constraints
│   └── functions/
│       └── cleanup-questions/
│           └── index.ts            # Edge Function: auto-delete 30-day-old questions
│
├── middleware/
│   ├── gate-guard.ts               # Pintu 1: checks gate_access cookie
│   ├── auth.ts                     # Pintu 2: checks Supabase OAuth session
│   └── role-guard.ts               # Pintu 3: checks profile.role is set
│
├── server/api/
│   └── verify-gate.post.ts         # Server-only gate password validation (rate limited)
│
├── composables/
│   ├── useAdminAuth.ts             # Role + session state management
│   ├── useQuestions.ts             # All CRUD, realtime, anti-spam logic
│   ├── useFingerprint.ts           # Browser fingerprint for anti-spam upvotes
│   └── useUI.ts                    # Sidebar + reply modal state
│
├── layouts/
│   ├── default.vue                 # Public layout (max-w-md, mobile-first)
│   ├── dashboard.vue               # Dashboard layout (sidebar + topbar)
│   └── gate.vue                    # Minimal centered layout for gate pages
│
├── components/
│   ├── AppHeader.vue               # Emerald top header for jemaah pages
│   ├── EmptyState.vue              # Reusable empty state illustration
│   ├── QuestionCard.vue            # Unified card (mode: jemaah/admin/ustadz)
│   ├── QuestionCardSkeleton.vue    # Loading skeleton for cards
│   ├── AdminAction.vue             # Approve / Reject buttons (admin sub-component)
│   ├── UstadzReply.vue             # Reply trigger button (ustadz sub-component)
│   └── Dashboard/
│       ├── Sidebar.vue             # Emerald sidebar (emerald-900)
│       ├── UserProfile.vue         # Top-right avatar + role badge
│       ├── ReplyModal.vue          # Answer textarea modal (ustadz)
│       └── StatCard.vue            # Summary metric card
│
└── pages/
    ├── index.vue                   # Jemaah: feed (Semua/Terjawab/Trending tabs)
    ├── ask.vue                     # Jemaah: submit question form
    ├── success.vue                 # Jemaah: post-submit confirmation + ticket ID
    ├── password-page.vue           # Gate 1: emerald-900 password entry
    ├── login-gate.vue              # Gate 2: Google OAuth login
    ├── select-role.vue             # Gate 3: pick Admin or Ustadz
    └── dashboard/
        ├── index.vue               # Admin: moderation | Ustadz: answer queue
        ├── archive.vue             # Archive: pin/unpin, 30-day countdown, edit answer
        └── profile.vue             # Profile: stats, role switcher, logout
```

---

## ⚡ Quick Start

### 1. Clone & Install

```bash
git clone <your-repo-url> tanya-ustadz-app
cd tanya-ustadz-app
npm install
```

### 2. Environment Variables

```bash
cp .env.example .env
```

Edit `.env`:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
ADMIN_GATE_PASSWORD=your-secret-gate-password
```

> ⚠️ **NEVER commit `.env` to git.** It is already in `.gitignore`.

### 3. Run Development Server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000)

---

## 🗄️ Supabase Setup

### Step 1: Create Supabase Project

1. Go to [supabase.com](https://supabase.com) → New Project
2. Copy your **Project URL** and **anon key** → paste into `.env`

### Step 2: Run SQL Migration

In Supabase Dashboard → **SQL Editor** → paste the entire content of:

```
supabase/migrations/setup.sql
```

This creates:
- `questions` table with constraints (status enum, char limits)
- `question_votes` table (anti-spam upvote)
- `profiles` table (linked to `auth.users`)
- All RLS policies (role-based column-level access)
- Triggers: auto-create profile on signup, sync upvote count
- Indexes for performance

### Step 3: Enable Google OAuth

1. Supabase Dashboard → **Authentication** → **Providers** → **Google**
2. Enable Google and paste your **Google Client ID** and **Client Secret**
3. Add redirect URL to Google Console:
   ```
   https://your-project.supabase.co/auth/v1/callback
   ```

### Step 4: Enable Realtime

In Supabase Dashboard → **Database** → **Replication**:

Enable realtime for:
- `questions` table
- `question_votes` table

Or run in SQL Editor:
```sql
alter publication supabase_realtime add table questions;
alter publication supabase_realtime add table question_votes;
```

### Step 5: Deploy Edge Function (Auto-delete 30 days)

Using Supabase CLI:

```bash
# Install CLI
npm install -g supabase

# Link your project
supabase link --project-ref your-project-ref

# Deploy the function
supabase functions deploy cleanup-questions

# Schedule: run every day at midnight UTC
supabase functions schedule cleanup-questions --cron "0 0 * * *"
```

Set the required secrets for the edge function:
```bash
supabase secrets set SUPABASE_URL=https://your-project.supabase.co
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

---

## 🔐 Security Architecture

### 3-Layer Access Gate (Admin Portal)

```
URL /password-page
        │
        ▼  (POST /api/verify-gate — server-side only)
   Gate 1: Password Gate
   - Password stored in .env (ADMIN_GATE_PASSWORD)
   - Max 5 failed attempts / IP / 15 minutes
   - 500ms delay on each failure
   - Sets HttpOnly + SameSite=Strict cookie (24h)
        │
        ▼  (Supabase Google OAuth)
   Gate 2: Google Login
   - OAuth via Supabase
        │
        ▼  (profiles.role check)
   Gate 3: Role Selection
   - Admin or Ustadz
   - Saved to profiles table
   - Stored in composable state
        │
        ▼
   /dashboard (protected by all 3 middleware)
```

### RLS Policy Summary

| Role | SELECT | INSERT | UPDATE |
|------|--------|--------|--------|
| Jemaah (anon) | `status = answered` only | ✅ (status=pending, no answer) | ❌ |
| Admin | All questions | ❌ | `status → verified/rejected` only, `answer` must be null |
| Ustadz | `status in (verified, answered)` | ❌ | `status → answered`, `answer` required |

---

## 🔄 Data Flow

### Jemaah Flow
```
/ask (submit) → status=pending → /success (ticket ID shown)
/index → fetchAnsweredQuestions() → realtime UPDATE watch
```

### Admin Flow
```
/dashboard → fetchPendingQuestions() → realtime INSERT watch
  → approve → status=verified (Ustadz sees it)
  → reject  → status=rejected (goes to archive)
/dashboard/archive → pin toggle, 30-day countdown
```

### Ustadz Flow
```
/dashboard → fetchVerifiedQuestions() → realtime UPDATE watch
  → open ReplyModal → validate question still exists → answerQuestion()
  → status=answered (Jemaah sees it in real-time)
/dashboard/archive → edit past answers
```

---

## 🎨 Design System

| Token | Value | Usage |
|-------|-------|-------|
| `emerald-600` | `#059669` | Primary buttons, links, active states |
| `emerald-900` | `#064e3b` | Gate page background, sidebar |
| `amber-50/600` | — | Pending question cards |
| `max-w-md` | 448px | Jemaah page max width |
| Full-width | — | Dashboard layout |

---

## 🚀 Deployment (Vercel)

### 1. Push to GitHub

```bash
git add .
git commit -m "initial: tanya ustadz app"
git push origin main
```

### 2. Deploy to Vercel

1. [vercel.com](https://vercel.com) → Import repository
2. Framework: **Nuxt.js** (auto-detected)
3. Add Environment Variables in Vercel dashboard:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `ADMIN_GATE_PASSWORD`

4. Deploy → Done ✅

### 3. Update Supabase OAuth Redirect

After deploying, add your production URL to Supabase:

- Dashboard → Authentication → URL Configuration
- Add: `https://your-app.vercel.app` to **Site URL**
- Add: `https://your-app.vercel.app/**` to **Redirect URLs**

Also update Google Cloud Console OAuth redirect URIs.

---

## 📋 Question Categories

| Category | Description |
|----------|-------------|
| Fikih | Ibadah, Shalat, Puasa, dll |
| Akhlak & Adab | Perilaku sehari-hari |
| Keluarga | Pernikahan, Parenting, Waris |
| Muamalah | Ekonomi, Jual Beli, Kerja |
| Umum | Pertanyaan di luar kategori di atas |

---

## ✅ Status Enum (Strict — Do Not Add New Values)

| Status | Description |
|--------|-------------|
| `pending` | Default dari jamaah, menunggu moderasi |
| `verified` | Disetujui admin, siap dijawab ustadz |
| `rejected` | Ditolak admin, masuk archive |
| `answered` | Sudah dijawab ustadz, muncul di public |

---

## ⚠️ Production Checklist

- [ ] `.env` tidak di-commit ke git
- [ ] Supabase RLS diaktifkan untuk semua tabel
- [ ] Google OAuth production redirect URL sudah ditambahkan
- [ ] Edge Function cleanup-questions sudah di-deploy dan dijadwalkan
- [ ] Realtime enabled untuk tabel `questions`
- [ ] Environment variables sudah diset di Vercel/Netlify
- [ ] `npm run build` berjalan tanpa error TypeScript
- [ ] `npm run typecheck` clean

---

## 📜 License

Internal project — AhsanTV © 2026
