# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**CineProd** — A film production database management system built for CMPE344 (Database Management Systems and Programming II). It has two parts:

- `database/` — PostgreSQL schema, seed data, analytical queries, and PL/pgSQL triggers/procedures
- `frontend/` — Next.js 15 app (App Router, React 18, Tailwind CSS, shadcn/ui)

## Frontend Development

All frontend commands run from the `frontend/` directory:

```bash
cd frontend
npm run dev      # Start dev server (localhost:3000)
npm run build    # Production build
npm run lint     # ESLint
```

**Environment:** Copy `.env.local.example` to `.env.local` and set `NEXT_PUBLIC_API_URL` to the backend URL (default: `http://localhost:8000`).

## Database Setup

Run SQL files in order against a PostgreSQL database:

```bash
psql -U <user> -d <db> -f database/schema.sql   # Create tables
psql -U <user> -d <db> -f database/seed.sql     # Populate data
psql -U <user> -d <db> -f database/plsql.sql    # Install triggers & procedures
psql -U <user> -d <db> -f database/queries.sql  # Run analytical queries
```

## Architecture

### Mock vs Real Backend

The frontend currently runs in **mock mode** by default. `frontend/src/lib/axios.js` is NOT a real axios instance — it's a full in-memory mock that intercepts all API calls and handles them locally using `mockData.js`. This means the app works without any backend. To switch to a real backend, replace `axios.js` with a real axios instance that reads from `NEXT_PUBLIC_API_URL`.

### Auth Flow

`AuthContext.jsx` manages auth state via `localStorage` (`access_token`, `refresh_token`). Tokens use a fake JWT format (`fake.<base64-payload>.sig`) that is decoded by splitting on `.` and base64-decoding the middle segment. `RouteGuard.jsx` wraps the entire app and redirects unauthenticated users to `/login`.

User roles: `admin`, `producer`, `crew_member`, `accountant`. Role helpers (`isAdmin()`, `isProducer()`, `isAccountant()`) are available from `useAuth()`.

### Frontend Route Structure

App Router pages under `frontend/src/app/`:
- `/` — Dashboard with stats and recent films
- `/films/` — Film list; `/films/[id]` — Film detail (crew roster, budget)
- `/crew/` — Crew member management
- `/expenses/` — Expense tracking
- `/stats/` — Analytical query results (matches `queries.sql`)
- `/admin/users/` — User management (admin only)
- `/login`, `/register` — Public routes

### Database Schema

8 tables with this dependency order: `users` → `departments` → `films` → `crew_members` → `film_crew` → `budgets` → `expenses` → `audit_log`

Key constraints:
- Film `status` enum: `development`, `pre_production`, `production`, `post_production`, `completed`, `cancelled`
- Expense `category` enum: `equipment`, `location`, `crew`, `post_production`, `marketing`, `other`
- `film_crew` has a UNIQUE constraint on `(film_id, crew_id)` enforced both by the schema and a PL/pgSQL trigger

### PL/pgSQL Objects

- **`trg_film_audit`** — AFTER trigger on `films`; logs all INSERT/UPDATE/DELETE to `audit_log` as JSONB
- **`trg_no_duplicate_assignment`** — BEFORE INSERT trigger on `film_crew`; raises exception on duplicate assignments
- **`create_film()`** — Stored procedure; enforces that only `producer`/`admin` roles can create films
- **`record_expense()`** — Stored procedure; enforces that only `accountant`/`admin` roles can add expenses
- **`get_film_budget_status(film_id)`** — Function; returns `'over_budget'`, `'under_budget'`, or `'no_budget_set'`

### Shared Components

Located in `frontend/src/components/`:
- `DataTable.jsx` — Generic table with search/sort used across all list pages
- `Modal.jsx` — Dialog wrapper for create/edit forms
- `Navbar.jsx` — Top nav with `StatusBadge` (film status color indicator), exported and reused on the dashboard
- `RouteGuard.jsx` — Auth gate wrapping the entire layout
- `ui/` — shadcn/ui primitives (button, card, dialog, etc.)
