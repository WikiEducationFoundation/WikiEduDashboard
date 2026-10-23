# Schools where instructors can add the LTI 1.1 tool themselves

At some schools, an instructor can add the Dashboard's LTI 1.1 tool to their own
Canvas course (Settings → Apps → + App, with a key and secret) without an
administrator; see `docs/canvas_instructor_install.md`. Elsewhere the course
needs the admin-installed LTI 1.3 tool. On 2026-09-17 we checked the 205
institutions with Fall 2026 courses for which ones allow the self-service path,
to decide where to offer it.

`fall_2026_instructors.rb` lists the instructors of Fall 2026 courses at those
schools: school, course, name, username and email, with the school's verdict.
Paste it into a production Rails console; it writes
`~/fall_2026_lti11_self_service_instructors.csv`.

- `yes`: confirmed on a live institutional page.
- `likely_yes`: the research found no restriction. The instructor should check
  for the + App button before relying on it.

Schools not in either list were confirmed to need an admin or a review (about
44), or were never reached by the research (about half of the 205).

For another term, change the campaign slug and recheck the lists. Keys are the
raw `Course#school` strings, so one institution may need several spellings. The
output has instructor emails; keep it outside the repo.

(README written by Claude Code.)
