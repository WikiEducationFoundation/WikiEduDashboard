# Phase 1 labeling rubric: collaboration mode

You are labeling Wiki Education classroom courses by how students divided up
their main Wikipedia writing project. Each input line is one course packet
(JSON). Judge each course independently from its packet alone.

## Packet fields

- `title`, `school`, `term`, `subject`, `level`, `start`, `end`
- `description`: the course description as entered by the instructor. Names
  may appear as tokens like `[INSTRUCTOR_1]` or `[STUDENT_3]`.
- `custom_timeline_text`: timeline blocks the instructor wrote or customized
  (Wiki Education's standard template text has been removed). Often HTML.
  Empty if the instructor used only template text.
- `top_assigned_articles`: articles students were assigned to through the
  Dashboard, with the number of distinct students assigned to each.
- `top_edited_articles`: mainspace (live) articles the class edited, with each
  article's share of the class's mainspace characters added, and
  `student_editors` (number of students who edited it; `null` means no data,
  which is normal before 2020).
- `metrics`:
  - `enrolled_students`
  - `assign_*`: from Dashboard assignments. `students` = students with an
    assignment; `articles` = distinct assigned articles; `top1_share` /
    `top3_share` = share of those students on the most-shared one / three
    articles; `median_group` = median over students of the size of the
    biggest group they belong to (1 = alone); `only_top3` = share of students
    whose every assignment is among the top three.
  - `edit_*`: the same measures from who actually edited each mainspace article
    (2020+ only).
  - `char_*`: `total` mainspace characters added, number of `articles`, and the
    share in the biggest one / three articles.

## Caveats

- Mainspace data shows only work that reached live articles. Many courses draft
  in sandboxes and move little to mainspace, so a single dominant mainspace
  article can be a small shared exercise rather than the main project. Weigh
  the character totals: a shared article with a few hundred characters is an
  exercise, not a project.
- Small shared exercises (everyone adds a citation to one article, evaluates
  an article, copyedits a sample page) are not the main project.
- Assignments can be incomplete: some classes never record assignments, or
  assign a whole class to one article as a placeholder.
- Text evidence (the instructor describing the project design) outranks
  metrics when they conflict, but say so in the reason.

## Labels

`mode` — the design of the main writing project:

- `whole_class`: all or most of the class (roughly 75%+ of students) worked
  together on one article or a very small number of articles (at most 3), in
  groups of at least 5 that are a large share of the class. A class split into
  2–3 large teams, each owning one article, counts.
- `small_group`: groups of 2–5 students per article, with more than 3 articles
  in the class overall.
- `individual`: most students had their own article.
- `mixed`: two designs of comparable weight, e.g. individual articles plus a
  substantial whole-class article, or a design that changed partway through.
- `unclear`: not enough evidence to choose.

`shared_articles`: titles of the articles the whole class or its large teams
worked on (only for `whole_class` or `mixed`; otherwise `[]`).

`instructor_participation`: `yes` if the text says the instructor edits the
article(s) alongside students or writes with them; `no` if the text says
otherwise; `unknown` if not stated (the usual case).

`evidence`: `text`, `metrics` or `both` — what the label mainly rests on.

`confidence`: `high`, `medium` or `low`.

`reason`: one sentence, citing the specific evidence.

## Output

One JSON object per course, one per line (JSONL), in input order:

```json
{"course_id": 123, "mode": "whole_class", "shared_articles": ["Cognitive Surplus"], "instructor_participation": "unknown", "evidence": "metrics", "confidence": "high", "reason": "All 13 assigned students share one article, which holds 96% of the class's 30k mainspace characters."}
```
