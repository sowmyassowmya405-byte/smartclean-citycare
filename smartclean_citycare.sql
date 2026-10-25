/* =====================================================
   SmartClean - CityCare : MySQL Database
   How to run:
   1. Open phpMyAdmin (XAMPP) or MySQL Workbench
   2. Open the SQL tab, paste this whole file, click Go
   ===================================================== */

CREATE DATABASE IF NOT EXISTS citycare_db
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE citycare_db;

-- Remove old tables (so the script can be run again and again)
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS feedback, notifications, complaint_history,
                     complaints, status_info, categories, departments, users;
DROP VIEW  IF EXISTS v_complaints;
SET FOREIGN_KEY_CHECKS = 1;


/* =====================================================
   PART 1 : TABLES
   ===================================================== */

-- 1. Users (citizens and admin)
CREATE TABLE users (
  user_id     INT AUTO_INCREMENT PRIMARY KEY,
  full_name   VARCHAR(100) NOT NULL,
  email       VARCHAR(100) NOT NULL UNIQUE,
  password    VARCHAR(255) NOT NULL,
  role        ENUM('citizen','admin') NOT NULL DEFAULT 'citizen',
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Complaint categories (garbage, water, streetlights ...)
CREATE TABLE categories (
  category_id    INT AUTO_INCREMENT PRIMARY KEY,
  category_name  VARCHAR(100) NOT NULL UNIQUE
);

-- 3. Departments / staff teams
CREATE TABLE departments (
  dept_id    INT AUTO_INCREMENT PRIMARY KEY,
  dept_name  VARCHAR(100) NOT NULL UNIQUE
);

-- 4. Meaning of each status (as given by the teacher)
CREATE TABLE status_info (
  status_name  ENUM('Pending','In Progress','Resolved') PRIMARY KEY,
  description  VARCHAR(255) NOT NULL
);

-- 5. Complaints (main table)
CREATE TABLE complaints (
  complaint_id  INT AUTO_INCREMENT PRIMARY KEY,      -- shown as SC-1001, SC-1002 ...
  user_id       INT NOT NULL,
  category_id   INT NOT NULL,
  description   TEXT NOT NULL,
  location      VARCHAR(255) NOT NULL,
  image_path    VARCHAR(255) NULL,                   -- file name of the uploaded photo
  status        ENUM('Pending','In Progress','Resolved') NOT NULL DEFAULT 'Pending',
  dept_id       INT NULL,                            -- department it is assigned to
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id)     REFERENCES users(user_id)           ON DELETE CASCADE,
  FOREIGN KEY (category_id) REFERENCES categories(category_id),
  FOREIGN KEY (dept_id)     REFERENCES departments(dept_id)     ON DELETE SET NULL
) AUTO_INCREMENT = 1001;                               -- first complaint ID = 1001

-- 6. History of every complaint (what happened and when)
CREATE TABLE complaint_history (
  history_id    INT AUTO_INCREMENT PRIMARY KEY,
  complaint_id  INT NOT NULL,
  message       VARCHAR(255) NOT NULL,
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (complaint_id) REFERENCES complaints(complaint_id) ON DELETE CASCADE
);

-- 7. Notifications for users
CREATE TABLE notifications (
  notification_id  INT AUTO_INCREMENT PRIMARY KEY,
  user_id          INT NOT NULL,
  message          VARCHAR(255) NOT NULL,
  is_read          TINYINT(1) NOT NULL DEFAULT 0,    -- 0 = unread, 1 = read
  created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- 8. Feedback and rating (one per complaint)
CREATE TABLE feedback (
  feedback_id   INT AUTO_INCREMENT PRIMARY KEY,
  complaint_id  INT NOT NULL UNIQUE,
  user_id       INT NOT NULL,
  rating        TINYINT NOT NULL,
  comment       VARCHAR(255) NULL,
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_rating CHECK (rating BETWEEN 1 AND 5),
  FOREIGN KEY (complaint_id) REFERENCES complaints(complaint_id) ON DELETE CASCADE,
  FOREIGN KEY (user_id)      REFERENCES users(user_id)           ON DELETE CASCADE
);


/* =====================================================
   PART 2 : STARTING DATA
   ===================================================== */

INSERT INTO status_info VALUES
  ('Pending',     'The complaint has been received.'),
  ('In Progress', 'The cleaning team is working on it.'),
  ('Resolved',    'The issue has been addressed.');

INSERT INTO departments (dept_name) VALUES
  ('Sanitation'), ('Water Board'), ('Electricity'), ('Roads & Works'),
  ('Drainage'), ('Parks'), ('General Office');

INSERT INTO categories (category_name) VALUES
  ('Garbage and waste collection'), ('Water supply'), ('Streetlights'),
  ('Roads and potholes'), ('Drainage and sewage'), ('Public toilets'),
  ('Parks and public areas'), ('Other civic issues');

-- Demo users. Passwords are stored as SHA-256 hash (not plain text).
-- Admin  : admin@citycare.com   / admin123
-- Citizen: citizen@demo.com     / demo123
INSERT INTO users (full_name, email, password, role) VALUES
  ('Admin',        'admin@citycare.com', SHA2('admin123', 256), 'admin'),
  ('Demo Citizen', 'citizen@demo.com',   SHA2('demo123', 256),  'citizen');

-- Two sample complaints
INSERT INTO complaints (user_id, category_id, description, location, status, dept_id) VALUES
  (2, 3, 'Streetlight not working for a week.', '4th Cross Road', 'In Progress', 3),
  (2, 4, 'Large pothole near the bus stop.',    'Main Road, near bus stop', 'Pending', NULL);

INSERT INTO complaint_history (complaint_id, message) VALUES
  (1001, 'Complaint submitted'),
  (1001, 'Assigned to Electricity'),
  (1002, 'Complaint submitted');

INSERT INTO notifications (user_id, message) VALUES
  (2, 'Your complaint SC-1001 was assigned to Electricity and is now In Progress.');


/* =====================================================
   PART 3 : VIEW (a ready-made table to show complaints)
   ===================================================== */

CREATE VIEW v_complaints AS
SELECT  CONCAT('SC-', c.complaint_id)  AS complaint_code,
        c.complaint_id,
        u.full_name                    AS citizen_name,
        u.email                        AS citizen_email,
        cat.category_name,
        c.description,
        c.location,
        c.image_path,
        c.status,
        s.description                  AS status_description,
        d.dept_name,
        c.created_at,
        c.updated_at
FROM complaints c
JOIN users        u   ON u.user_id      = c.user_id
JOIN categories   cat ON cat.category_id = c.category_id
JOIN status_info  s   ON s.status_name   = c.status
LEFT JOIN departments d ON d.dept_id     = c.dept_id;


/* =====================================================
   PART 4 : QUERIES FOR EACH FEATURE
   (sample values are used so you can run and show them)
   ===================================================== */

-- ---- 1. User registration ----
INSERT INTO users (full_name, email, password)
VALUES ('Ravi Kumar', 'ravi@gmail.com', SHA2('ravi123', 256));

-- ---- 2. Login (returns one row if email and password are correct) ----
SELECT user_id, full_name, role
FROM users
WHERE email = 'citizen@demo.com' AND password = SHA2('demo123', 256);

-- ---- 3. Submit a complaint ----
INSERT INTO complaints (user_id, category_id, description, location)
VALUES (2, 1, 'Garbage not collected for 4 days.', 'Market Road');

-- save the first history line for the new complaint
INSERT INTO complaint_history (complaint_id, message)
VALUES (LAST_INSERT_ID(), 'Complaint submitted');

-- tell the admin about it
INSERT INTO notifications (user_id, message)
VALUES (1, CONCAT('New complaint SC-', LAST_INSERT_ID(), ' received.'));

-- ---- 4. My complaints (citizen history) ----
SELECT complaint_code, category_name, description, location,
       status, status_description, dept_name, created_at
FROM v_complaints
WHERE citizen_email = 'citizen@demo.com'
ORDER BY created_at DESC;

-- ---- 5. Track a complaint by ID ----
SELECT complaint_code, category_name, status, status_description, dept_name
FROM v_complaints
WHERE complaint_id = 1001;

-- history (timeline) of that complaint
SELECT created_at, message
FROM complaint_history
WHERE complaint_id = 1001
ORDER BY created_at;

-- ---- 6. Admin: all complaints ----
SELECT * FROM v_complaints ORDER BY created_at DESC;

-- ---- 7. Admin: search and filter ----
SELECT * FROM v_complaints
WHERE status = 'Pending'
  AND category_name = 'Roads and potholes'
  AND (description LIKE '%pothole%' OR location LIKE '%pothole%');

-- ---- 8. Admin: assign complaint to a department ----
-- (a Pending complaint also becomes In Progress)
UPDATE complaints
SET dept_id = 4,
    status  = IF(status = 'Pending', 'In Progress', status)
WHERE complaint_id = 1002;

INSERT INTO complaint_history (complaint_id, message)
VALUES (1002, 'Assigned to Roads & Works');

INSERT INTO notifications (user_id, message)
SELECT user_id, 'Complaint SC-1002 was assigned to Roads & Works and is now In Progress.'
FROM complaints WHERE complaint_id = 1002;

-- ---- 9. Admin: update status / mark as resolved ----
UPDATE complaints SET status = 'Resolved' WHERE complaint_id = 1001;

INSERT INTO complaint_history (complaint_id, message)
VALUES (1001, 'Status changed to Resolved');

INSERT INTO notifications (user_id, message)
SELECT user_id, 'Complaint SC-1001 is now: Resolved.'
FROM complaints WHERE complaint_id = 1001;

-- ---- 10. Citizen: feedback and rating (only after Resolved) ----
INSERT INTO feedback (complaint_id, user_id, rating, comment)
VALUES (1001, 2, 5, 'Fixed quickly. Thank you!');

-- ---- 11. Notifications ----
-- unread notifications of a user
SELECT message, created_at
FROM notifications
WHERE user_id = 2 AND is_read = 0
ORDER BY created_at DESC;

-- mark them as read
UPDATE notifications SET is_read = 1 WHERE user_id = 2;

-- ---- 12. Admin: manage users ----
SELECT user_id, full_name, email, created_at
FROM users
WHERE role = 'citizen';

-- delete a user (their complaints are deleted too)
-- DELETE FROM users WHERE user_id = 3;

-- ---- 13. Reports ----
-- complaints by status
SELECT status, COUNT(*) AS total
FROM complaints
GROUP BY status;

-- complaints by category
SELECT cat.category_name, COUNT(*) AS total
FROM complaints c
JOIN categories cat ON cat.category_id = c.category_id
GROUP BY cat.category_name
ORDER BY total DESC;

-- complaints by department
SELECT d.dept_name, COUNT(*) AS total
FROM complaints c
JOIN departments d ON d.dept_id = c.dept_id
GROUP BY d.dept_name;

-- average rating
SELECT ROUND(AVG(rating), 1) AS average_rating, COUNT(*) AS total_ratings
FROM feedback;

-- dashboard numbers in one query
SELECT COUNT(*)                          AS total,
       SUM(status = 'Pending')           AS pending,
       SUM(status = 'In Progress')       AS in_progress,
       SUM(status = 'Resolved')          AS resolved
FROM complaints;