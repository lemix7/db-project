-- ============================================================
-- Film Production Database Management System
-- CMPE344 - Database Management Systems and Programming II
-- seed.sql — Run AFTER schema.sql
-- ============================================================

-- ============================================================
-- USERS (8 rows: 1 admin, 2 producers, 3 crew_members, 2 accountants)
-- All passwords are bcrypt hashes of 'Password123!'
-- ============================================================
INSERT INTO users (username, email, password_hash, full_name, role) VALUES
('admin_sara',  'sara@cineprod.com',  '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMqJqhcanFl9MayNomU.u/IZBq', 'Sara Mitchell', 'admin'),
('prod_james',  'james@cineprod.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMqJqhcanFl9MayNomU.u/IZBq', 'James Carter',  'producer'),
('prod_linda',  'linda@cineprod.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMqJqhcanFl9MayNomU.u/IZBq', 'Linda Torres',  'producer'),
('crew_alex',   'alex@cineprod.com',  '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMqJqhcanFl9MayNomU.u/IZBq', 'Alex Johnson',  'crew_member'),
('crew_maya',   'maya@cineprod.com',  '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMqJqhcanFl9MayNomU.u/IZBq', 'Maya Patel',    'crew_member'),
('crew_omar',   'omar@cineprod.com',  '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMqJqhcanFl9MayNomU.u/IZBq', 'Omar Hassan',   'crew_member'),
('acc_ryan',    'ryan@cineprod.com',  '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMqJqhcanFl9MayNomU.u/IZBq', 'Ryan Brooks',   'accountant'),
('acc_nina',    'nina@cineprod.com',  '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMqJqhcanFl9MayNomU.u/IZBq', 'Nina Volkova',  'accountant');

-- ============================================================
-- DEPARTMENTS (5 rows)
-- ============================================================
INSERT INTO departments (name, description) VALUES
('Directing',        'Responsible for the creative vision and direction of the film'),
('Cinematography',   'Handles camera work, lighting, and visual composition'),
('Production Design','Oversees set design, art direction, and visual style'),
('Sound',            'Manages audio recording, sound design, and music'),
('Editing',          'Handles post-production video and audio editing');

-- ============================================================
-- FILMS (5 rows — created_by: prod_james=2, prod_linda=3)
-- ============================================================
INSERT INTO films (title, genre, status, start_date, end_date, description, created_by) VALUES
('Eclipse of Dawn',      'Drama',     'production',       '2024-03-01', '2024-09-30', 'A story of two estranged siblings reuniting after their father''s death.',     2),
('Neon Phantom',         'Sci-Fi',    'pre_production',   '2024-06-01', '2025-02-28', 'A cyberpunk thriller set in a dystopian city ruled by AI.',                   2),
('The Last Harvest',     'Thriller',  'post_production',  '2023-08-15', '2024-04-30', 'A farmer uncovers a dark conspiracy threatening his rural community.',         3),
('Laughing in the Rain', 'Comedy',    'development',      '2024-10-01', '2025-08-31', 'A quirky romantic comedy set during a music festival.',                        3),
('Iron Meridian',        'Action',    'completed',        '2022-01-10', '2023-05-20', 'An ex-soldier fights to protect his city from a rogue military faction.',      2);

-- ============================================================
-- CREW MEMBERS (6 rows — linked to user accounts)
-- ============================================================
INSERT INTO crew_members (user_id, department_id, job_title, phone, hire_date) VALUES
(2, 1, 'Senior Producer',         '+1-555-0101', '2018-04-15'),
(3, 1, 'Associate Producer',      '+1-555-0102', '2020-07-01'),
(4, 2, 'Director of Photography', '+1-555-0201', '2019-03-20'),
(5, 3, 'Art Director',            '+1-555-0301', '2021-01-10'),
(6, 4, 'Sound Designer',          '+1-555-0401', '2022-06-05'),
(1, 5, 'Post-Production Editor',  '+1-555-0501', '2017-09-12');

-- ============================================================
-- FILM CREW ASSIGNMENTS (8 rows)
-- ============================================================
INSERT INTO film_crew (film_id, crew_id, role_on_film) VALUES
(1, 1, 'Lead Producer'),
(1, 3, 'Director of Photography'),
(1, 4, 'Art Director'),
(2, 2, 'Producer'),
(2, 3, 'Cinematographer'),
(3, 2, 'Associate Producer'),
(3, 5, 'Sound Designer'),
(4, 1, 'Executive Producer');

-- ============================================================
-- BUDGETS (4 rows — one per film, created by accountants)
-- ============================================================
INSERT INTO budgets (film_id, total_amount, currency, created_by) VALUES
(1, 2500000.00, 'USD', 7),
(2, 5000000.00, 'USD', 7),
(3, 1800000.00, 'USD', 8),
(5,  950000.00, 'USD', 8);

-- ============================================================
-- EXPENSES (10 rows — recorded by accountants)
-- ============================================================
INSERT INTO expenses (film_id, category, description, amount, expense_date, recorded_by) VALUES
(1, 'equipment',       'Camera and lens rental for principal photography', 120000.00, '2024-03-15', 7),
(1, 'location',        'Location permits and fees for downtown shoot',      45000.00, '2024-03-20', 7),
(1, 'crew',            'Additional crew hires for action sequences',       210000.00, '2024-04-01', 7),
(1, 'post_production', 'VFX work for final act',                           380000.00, '2024-07-10', 8),
(2, 'equipment',       'Specialized drone and camera rigs',                200000.00, '2024-06-15', 7),
(2, 'location',        'Studio rental for interior sets',                  350000.00, '2024-07-01', 7),
(3, 'crew',            'Extended crew contracts due to schedule overrun',  320000.00, '2024-01-10', 8),
(3, 'post_production', 'Sound mixing and score recording',                  95000.00, '2024-03-05', 8),
(3, 'marketing',       'Trailer production and festival submissions',       180000.00, '2024-04-01', 8),
(5, 'equipment',       'Stunt equipment and pyrotechnics',                 430000.00, '2022-06-01', 7);
