-- ============================================================
-- Film Production Database Management System
-- CMPE344 - Database Management Systems and Programming II
-- schema.sql — Run this first
-- ============================================================

-- Drop tables in reverse dependency order (for clean re-runs)
DROP TABLE IF EXISTS audit_log    CASCADE;
DROP TABLE IF EXISTS expenses     CASCADE;
DROP TABLE IF EXISTS budgets      CASCADE;
DROP TABLE IF EXISTS film_crew    CASCADE;
DROP TABLE IF EXISTS crew_members CASCADE;
DROP TABLE IF EXISTS films        CASCADE;
DROP TABLE IF EXISTS departments  CASCADE;
DROP TABLE IF EXISTS users        CASCADE;

-- ============================================================
-- TABLE 1: users
-- Authentication + role management for all system actors.
-- Roles: admin, producer, crew_member, accountant
-- ============================================================
CREATE TABLE users (
    user_id       SERIAL PRIMARY KEY,
    username      VARCHAR(50)  UNIQUE NOT NULL,
    email         VARCHAR(100) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    full_name     VARCHAR(100),
    role          VARCHAR(20)  NOT NULL DEFAULT 'crew_member'
                  CHECK (role IN ('admin', 'producer', 'crew_member', 'accountant')),
    created_at    TIMESTAMP    DEFAULT NOW(),
    is_active     BOOLEAN      DEFAULT TRUE
);

-- ============================================================
-- TABLE 2: departments
-- Production departments (e.g. Directing, Cinematography).
-- ============================================================
CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    name          VARCHAR(100) UNIQUE NOT NULL,
    description   TEXT
);

-- ============================================================
-- TABLE 3: films
-- Films managed by producers.
-- ============================================================
CREATE TABLE films (
    film_id     SERIAL PRIMARY KEY,
    title       VARCHAR(200) NOT NULL,
    genre       VARCHAR(50),
    status      VARCHAR(20)  NOT NULL DEFAULT 'development'
                CHECK (status IN ('development', 'pre_production', 'production', 'post_production', 'completed', 'cancelled')),
    start_date  DATE,
    end_date    DATE,
    description TEXT,
    created_by  INTEGER      REFERENCES users(user_id) ON DELETE SET NULL,
    created_at  TIMESTAMP    DEFAULT NOW()
);

-- ============================================================
-- TABLE 4: crew_members
-- Staff profiles linked to a user account and department.
-- ============================================================
CREATE TABLE crew_members (
    crew_id       SERIAL PRIMARY KEY,
    user_id       INTEGER      UNIQUE REFERENCES users(user_id) ON DELETE CASCADE,
    department_id INTEGER      REFERENCES departments(department_id) ON DELETE SET NULL,
    job_title     VARCHAR(100) NOT NULL,
    phone         VARCHAR(20),
    hire_date     DATE         DEFAULT CURRENT_DATE
);

-- ============================================================
-- TABLE 5: film_crew
-- Many-to-many: crew members assigned to films.
-- ============================================================
CREATE TABLE film_crew (
    assignment_id   SERIAL PRIMARY KEY,
    film_id         INTEGER      NOT NULL REFERENCES films(film_id)        ON DELETE CASCADE,
    crew_id         INTEGER      NOT NULL REFERENCES crew_members(crew_id) ON DELETE CASCADE,
    role_on_film    VARCHAR(100),
    assigned_at     TIMESTAMP    DEFAULT NOW(),
    UNIQUE (film_id, crew_id)
);

-- ============================================================
-- TABLE 6: budgets
-- Total budget allocated per film. One budget per film.
-- ============================================================
CREATE TABLE budgets (
    budget_id    SERIAL PRIMARY KEY,
    film_id      INTEGER        UNIQUE NOT NULL REFERENCES films(film_id) ON DELETE CASCADE,
    total_amount NUMERIC(15, 2) NOT NULL CHECK (total_amount > 0),
    currency     VARCHAR(10)    DEFAULT 'USD',
    created_by   INTEGER        REFERENCES users(user_id) ON DELETE SET NULL,
    created_at   TIMESTAMP      DEFAULT NOW()
);

-- ============================================================
-- TABLE 7: expenses
-- Individual expense records charged against a film.
-- ============================================================
CREATE TABLE expenses (
    expense_id   SERIAL PRIMARY KEY,
    film_id      INTEGER        NOT NULL REFERENCES films(film_id) ON DELETE CASCADE,
    category     VARCHAR(50)    NOT NULL
                 CHECK (category IN ('equipment', 'location', 'crew', 'post_production', 'marketing', 'other')),
    description  TEXT,
    amount       NUMERIC(15, 2) NOT NULL CHECK (amount > 0),
    expense_date DATE           NOT NULL DEFAULT CURRENT_DATE,
    recorded_by  INTEGER        REFERENCES users(user_id) ON DELETE SET NULL
);

-- ============================================================
-- TABLE 8: audit_log
-- Populated exclusively by PL/pgSQL triggers.
-- Tracks all INSERT/UPDATE/DELETE on the films table.
-- ============================================================
CREATE TABLE audit_log (
    log_id      SERIAL PRIMARY KEY,
    table_name  VARCHAR(50),
    operation   VARCHAR(10) CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    record_id   INTEGER,
    changed_at  TIMESTAMP   DEFAULT NOW(),
    old_data    JSONB,
    new_data    JSONB
);
