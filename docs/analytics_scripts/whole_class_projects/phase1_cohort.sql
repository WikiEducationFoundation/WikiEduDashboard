-- Phase 1 of PLAN.md: final whole-class cohort tiers, combining the LLM label
-- (course_mode_labels) with page-history verification
-- (course_history_verification). H = at least 6 active students, >=60% of them
-- edited the top 3 shared pages, and the top page has >= max(5, 30% of active)
-- student editors.
--   A confirmed      LLM whole_class and H
--   B history_only   H, LLM mixed or unclear
--   C llm_only       LLM whole_class (high/medium), not H
--   D disputed       H but LLM small_group/individual, or LLM whole_class/low without H
DROP TABLE IF EXISTS whole_class_cohort;
CREATE TABLE whole_class_cohort AS
SELECT l.course_id, t.tier, l.mode, l.confidence, h.active_students, h.hist_top_editors,
       h.hist_top1_share, h.hist_top3_share, h.instructor_edits, h.top3_student_bytes,
       h.top3_other_bytes, l.shared_articles, l.reason
FROM course_mode_labels l
JOIN course_history_verification h USING (course_id)
JOIN (
  SELECT l2.course_id,
    CASE
      WHEN hv AND l2.mode = 'whole_class' THEN 'A_confirmed'
      WHEN hv AND l2.mode IN ('mixed', 'unclear') THEN 'B_history_only'
      WHEN NOT hv AND l2.mode = 'whole_class' AND l2.confidence IN ('high', 'medium') THEN 'C_llm_only'
      WHEN hv OR l2.mode = 'whole_class' THEN 'D_disputed'
    END AS tier
  FROM course_mode_labels l2 JOIN (
    SELECT course_id, (active_students >= 6 AND hist_top3_share >= 0.6
      AND hist_top_editors >= GREATEST(5, 0.3 * active_students)) AS hv
    FROM course_history_verification
  ) v USING (course_id)
) t USING (course_id)
WHERE t.tier IS NOT NULL;
