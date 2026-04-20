-- ============================================================
-- Film Production Database Management System
-- CMPE344 - Database Management Systems and Programming II
-- queries.sql — Run against populated database
-- ============================================================

-- ============================================================
-- QUERY 1: Film budget summary — allocated vs total spent
-- Techniques: JOIN (3 tables), SUM, COALESCE, GROUP BY, ORDER BY
-- ============================================================
SELECT
    f.title                                         AS film,
    f.status,
    b.total_amount                                  AS budget_allocated,
    COALESCE(SUM(e.amount), 0)                      AS total_spent,
    b.total_amount - COALESCE(SUM(e.amount), 0)     AS remaining_budget
FROM films f
JOIN budgets  b ON f.film_id = b.film_id
LEFT JOIN expenses e ON f.film_id = e.film_id
GROUP BY f.film_id, f.title, f.status, b.total_amount
ORDER BY total_spent DESC;

-- ============================================================
-- QUERY 2: Films with no crew assigned
-- Techniques: Subquery (NOT IN), JOIN
-- ============================================================
SELECT
    f.film_id,
    f.title,
    f.status,
    f.start_date,
    u.full_name AS created_by
FROM films f
JOIN users u ON f.created_by = u.user_id
WHERE f.film_id NOT IN (
    SELECT DISTINCT film_id FROM film_crew
)
ORDER BY f.created_at DESC;

-- ============================================================
-- QUERY 3: Most active crew members (by number of films)
-- Techniques: JOIN, COUNT, GROUP BY, ORDER BY
-- ============================================================
SELECT
    u.full_name,
    cm.job_title,
    d.name                      AS department,
    COUNT(fc.assignment_id)     AS films_assigned
FROM crew_members cm
JOIN users        u  ON cm.user_id       = u.user_id
JOIN departments  d  ON cm.department_id = d.department_id
LEFT JOIN film_crew fc ON cm.crew_id     = fc.crew_id
GROUP BY cm.crew_id, u.full_name, cm.job_title, d.name
ORDER BY films_assigned DESC;

-- ============================================================
-- QUERY 4: Department workload statistics
-- Techniques: LEFT JOIN, COUNT DISTINCT, GROUP BY, ORDER BY
-- ============================================================
SELECT
    d.name                              AS department,
    COUNT(DISTINCT cm.crew_id)          AS total_crew,
    COUNT(DISTINCT fc.film_id)          AS films_involved,
    COUNT(fc.assignment_id)             AS total_assignments
FROM departments d
LEFT JOIN crew_members cm ON d.department_id = cm.department_id
LEFT JOIN film_crew    fc ON cm.crew_id       = fc.crew_id
GROUP BY d.department_id, d.name
ORDER BY total_assignments DESC;

-- ============================================================
-- QUERY 5: Full crew roster per film
-- Techniques: 4-table JOIN, ORDER BY
-- ============================================================
SELECT
    f.title                     AS film,
    f.status,
    u.full_name                 AS crew_member,
    cm.job_title,
    d.name                      AS department,
    fc.role_on_film,
    fc.assigned_at
FROM film_crew fc
JOIN films        f  ON fc.film_id       = f.film_id
JOIN crew_members cm ON fc.crew_id       = cm.crew_id
JOIN users        u  ON cm.user_id       = u.user_id
JOIN departments  d  ON cm.department_id = d.department_id
ORDER BY f.title, d.name, u.full_name;

-- ============================================================
-- QUERY 6: Over-budget films
-- Techniques: JOIN, SUM, GROUP BY, HAVING (correlated comparison)
-- ============================================================
SELECT
    f.title                         AS film,
    f.status,
    b.total_amount                  AS budget,
    SUM(e.amount)                   AS total_spent,
    SUM(e.amount) - b.total_amount  AS overspend
FROM films f
JOIN budgets  b ON f.film_id = b.film_id
JOIN expenses e ON f.film_id = e.film_id
GROUP BY f.film_id, f.title, f.status, b.total_amount
HAVING SUM(e.amount) > b.total_amount
ORDER BY overspend DESC;

-- ============================================================
-- QUERY 7: Expense breakdown by film and category
-- Techniques: JOIN, SUM, AVG, COUNT, GROUP BY, ORDER BY
-- ============================================================
SELECT
    f.title                     AS film,
    e.category,
    COUNT(e.expense_id)         AS expense_count,
    SUM(e.amount)               AS total_amount,
    ROUND(AVG(e.amount), 2)     AS avg_amount,
    MIN(e.expense_date)         AS first_expense,
    MAX(e.expense_date)         AS last_expense
FROM expenses e
JOIN films f ON e.film_id = f.film_id
GROUP BY f.film_id, f.title, e.category
ORDER BY f.title, total_amount DESC;
