-- ============================================================
-- Film Production Database Management System
-- CMPE344 - Database Management Systems and Programming II
-- plsql.sql — Run AFTER schema.sql
-- (Create functions before their triggers)
-- ============================================================


-- ============================================================
-- BLOCK 1: TRIGGER — Audit log for all film changes
-- Auto-logs every INSERT, UPDATE, DELETE on the films table
-- into audit_log. No application code involvement needed.
-- ============================================================

CREATE OR REPLACE FUNCTION log_film_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (table_name, operation, record_id, new_data)
        VALUES ('films', 'INSERT', NEW.film_id, row_to_json(NEW)::jsonb);

    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (table_name, operation, record_id, old_data, new_data)
        VALUES ('films', 'UPDATE', NEW.film_id,
                row_to_json(OLD)::jsonb, row_to_json(NEW)::jsonb);

    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (table_name, operation, record_id, old_data)
        VALUES ('films', 'DELETE', OLD.film_id, row_to_json(OLD)::jsonb);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_film_audit
AFTER INSERT OR UPDATE OR DELETE ON films
FOR EACH ROW EXECUTE FUNCTION log_film_changes();

-- Test:
-- INSERT INTO films (title, genre, status, created_by)
--   VALUES ('Test Film', 'Drama', 'development', 1);
-- SELECT * FROM audit_log;


-- ============================================================
-- BLOCK 2: TRIGGER — Prevent duplicate crew assignments
-- Raises a descriptive exception BEFORE inserting a duplicate
-- (film_id, crew_id) combination into film_crew.
-- ============================================================

CREATE OR REPLACE FUNCTION prevent_duplicate_crew_assignment()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM film_crew
        WHERE film_id = NEW.film_id
          AND crew_id = NEW.crew_id
    ) THEN
        RAISE EXCEPTION
            'Crew member % is already assigned to film %.',
            NEW.crew_id, NEW.film_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_no_duplicate_assignment
BEFORE INSERT ON film_crew
FOR EACH ROW EXECUTE FUNCTION prevent_duplicate_crew_assignment();

-- Test:
-- INSERT INTO film_crew (film_id, crew_id, role_on_film)
--   VALUES (1, 1, 'Duplicate Test');  -- crew 1 is already on film 1


-- ============================================================
-- BLOCK 3: STORED PROCEDURE — Create a film with role check
-- Only users with role 'producer' or 'admin' may create films.
-- ============================================================

CREATE OR REPLACE PROCEDURE create_film(
    p_title       VARCHAR,
    p_genre       VARCHAR,
    p_status      VARCHAR,
    p_start_date  DATE,
    p_end_date    DATE,
    p_description TEXT,
    p_created_by  INTEGER
)
LANGUAGE plpgsql AS $$
DECLARE
    v_role VARCHAR(20);
BEGIN
    SELECT role INTO v_role
    FROM users
    WHERE user_id = p_created_by AND is_active = TRUE;

    IF v_role IS NULL THEN
        RAISE EXCEPTION 'User % does not exist or is inactive.', p_created_by;
    END IF;

    IF v_role NOT IN ('producer', 'admin') THEN
        RAISE EXCEPTION
            'User % (role: %) does not have permission to create films.',
            p_created_by, v_role;
    END IF;

    INSERT INTO films (title, genre, status, start_date, end_date, description, created_by)
    VALUES (p_title, p_genre, p_status, p_start_date, p_end_date, p_description, p_created_by);

    RAISE NOTICE 'Film "%" created successfully by user %.', p_title, p_created_by;
END;
$$;

-- Test (producer user_id=2):
-- CALL create_film('New Film', 'Action', 'development', '2025-01-01', '2025-12-31', 'A new action film.', 2);

-- Test (crew_member user_id=4 — should fail):
-- CALL create_film('Unauthorized', 'Drama', 'development', NULL, NULL, NULL, 4);


-- ============================================================
-- BLOCK 4: FUNCTION — Get film budget status
-- Returns TEXT: 'over_budget', 'under_budget', or 'no_budget_set'
-- ============================================================

CREATE OR REPLACE FUNCTION get_film_budget_status(p_film_id INTEGER)
RETURNS TEXT AS $$
DECLARE
    v_budget NUMERIC(15, 2);
    v_spent  NUMERIC(15, 2);
BEGIN
    SELECT total_amount INTO v_budget
    FROM budgets
    WHERE film_id = p_film_id;

    IF v_budget IS NULL THEN
        RETURN 'no_budget_set';
    END IF;

    SELECT COALESCE(SUM(amount), 0) INTO v_spent
    FROM expenses
    WHERE film_id = p_film_id;

    IF v_spent > v_budget THEN
        RETURN 'over_budget';
    ELSE
        RETURN 'under_budget';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Test:
-- SELECT get_film_budget_status(1);   -- film with budget and expenses
-- SELECT get_film_budget_status(4);   -- film with no budget set


-- ============================================================
-- BLOCK 5: STORED PROCEDURE — Record an expense with role check
-- Only users with role 'accountant' or 'admin' may add expenses.
-- ============================================================

CREATE OR REPLACE PROCEDURE record_expense(
    p_film_id      INTEGER,
    p_category     VARCHAR,
    p_description  TEXT,
    p_amount       NUMERIC,
    p_expense_date DATE,
    p_recorded_by  INTEGER
)
LANGUAGE plpgsql AS $$
DECLARE
    v_role         VARCHAR(20);
    v_film_exists  BOOLEAN;
BEGIN
    SELECT role INTO v_role
    FROM users
    WHERE user_id = p_recorded_by AND is_active = TRUE;

    IF v_role IS NULL THEN
        RAISE EXCEPTION 'User % does not exist or is inactive.', p_recorded_by;
    END IF;

    IF v_role NOT IN ('accountant', 'admin') THEN
        RAISE EXCEPTION
            'User % (role: %) is not authorized to record expenses.',
            p_recorded_by, v_role;
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM films WHERE film_id = p_film_id
    ) INTO v_film_exists;

    IF NOT v_film_exists THEN
        RAISE EXCEPTION 'Film % does not exist.', p_film_id;
    END IF;

    INSERT INTO expenses (film_id, category, description, amount, expense_date, recorded_by)
    VALUES (p_film_id, p_category, p_description, p_amount, p_expense_date, p_recorded_by);

    RAISE NOTICE 'Expense of % recorded for film % by user %.', p_amount, p_film_id, p_recorded_by;
END;
$$;

-- Test (accountant user_id=7):
-- CALL record_expense(1, 'equipment', 'Lighting rigs', 50000.00, '2024-05-01', 7);

-- Test (crew_member user_id=4 — should fail):
-- CALL record_expense(1, 'equipment', 'Unauthorized', 1000.00, '2024-05-01', 4);
