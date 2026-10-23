-- Phase 3 design, built before Phase 2 measurement: the courses to measure.
--   cohort           tiers A, B, C of whole_class_cohort
--   same_instructor  up to 3 individual/small-group courses (by rule mode) taught
--                    by an instructor of the cohort course, nearest in start date
--   matched          1 individual + 1 small-group course per cohort course with the
--                    same subject, start year within 1, and active-student count
--                    within a factor of 1.5; deterministic random pick
-- Comparison courses never come from whole_class_cohort (any tier).
DROP TABLE IF EXISTS course_active;
CREATE TABLE course_active (course_id INT PRIMARY KEY, active_students INT) AS
SELECT course_id, SUM(role = 0 AND revision_count > 0) AS active_students
FROM wcp_sanitized.courses_users WHERE course_id IS NOT NULL GROUP BY course_id;

DROP TABLE IF EXISTS comparison_pool;
CREATE TABLE comparison_pool (course_id INT PRIMARY KEY, mode_rule VARCHAR(16), subject VARCHAR(255),
                              start DATETIME, active_students INT) AS
SELECT m.course_id, m.mode_rule, c.subject, c.start, a.active_students
FROM collab_mode m
JOIN wcp_sanitized.courses c ON c.id = m.course_id
JOIN course_active a ON a.course_id = m.course_id
WHERE m.mode_rule IN ('individual', 'small_group') AND a.active_students >= 6
  AND m.course_id NOT IN (SELECT course_id FROM whole_class_cohort);

DROP TABLE IF EXISTS comparison_set;
CREATE TABLE comparison_set (course_id INT, role VARCHAR(16), anchor_course_id INT, tier VARCHAR(16),
                             mode VARCHAR(16), INDEX (course_id), INDEX (anchor_course_id));

INSERT INTO comparison_set
SELECT w.course_id, 'cohort', w.course_id, w.tier, 'whole_class'
FROM whole_class_cohort w WHERE w.tier IN ('A_confirmed', 'B_history_only', 'C_llm_only');

INSERT INTO comparison_set
SELECT course_id, 'same_instructor', anchor, tier, mode_rule FROM (
  SELECT p.course_id, w.course_id AS anchor, w.tier, p.mode_rule,
         ROW_NUMBER() OVER (PARTITION BY w.course_id
                            ORDER BY ABS(DATEDIFF(p.start, ac.start)), p.course_id) AS rn
  FROM whole_class_cohort w
  JOIN wcp_sanitized.courses ac ON ac.id = w.course_id
  JOIN instructor_courses i ON i.course_id = w.course_id
  JOIN instructor_courses j ON j.instructor_id = i.instructor_id AND j.course_id <> w.course_id
  JOIN comparison_pool p ON p.course_id = j.course_id
  WHERE w.tier IN ('A_confirmed', 'B_history_only', 'C_llm_only')
  GROUP BY p.course_id, w.course_id, w.tier, p.mode_rule, p.start, ac.start
) x WHERE rn <= 3;

INSERT INTO comparison_set
SELECT course_id, 'matched', anchor, tier, mode_rule FROM (
  SELECT p.course_id, w.course_id AS anchor, w.tier, p.mode_rule,
         ROW_NUMBER() OVER (PARTITION BY w.course_id, p.mode_rule
                            ORDER BY CRC32(CONCAT(p.course_id, ':', w.course_id))) AS rn
  FROM whole_class_cohort w
  JOIN wcp_sanitized.courses ac ON ac.id = w.course_id
  JOIN course_active aa ON aa.course_id = w.course_id
  JOIN comparison_pool p ON p.subject = ac.subject AND ABS(YEAR(p.start) - YEAR(ac.start)) <= 1
    AND p.active_students BETWEEN aa.active_students / 1.5 AND aa.active_students * 1.5
  WHERE w.tier IN ('A_confirmed', 'B_history_only', 'C_llm_only')
) x WHERE rn <= 1;
