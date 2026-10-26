# QuestionsController access-log check

`survey_endpoint_log_check.sh` checks the Wiki Ed production server's logs for
requests to the three `QuestionsController` endpoints that had no authorization
check until 5619bdbe2 (GHSA-3435-9pw5-6pxr):

- `GET /survey/question/results/:id.csv` (respondent usernames, emails and answers)
- `PUT /surveys/question_position` (reorders survey questions)
- `GET /surveys/question_group_question/:id` (question definition as JSON)

It is read-only. Run it as root on the server from the repo root:

```
ssh dashboard.wikiedu.org 'sudo bash -s' < docs/analytics_scripts/questions_controller_auth/survey_endpoint_log_check.sh
```

It prints:

1. Which Apache access-log config is enabled, and the logrotate settings.
2. Every access log and error log, with dates, and the earliest entry in
   each access log. Nothing before those entries can be checked.
3. One line per IP, method, endpoint and status, from the access logs: hits,
   distinct question ids, largest response, first and last time seen, and
   whether the same IP ever got a 200 on a `/survey/results/:id` page (which
   needs an admin session).
4. The same summary from the Rails request log, which Passenger writes into
   Apache's error logs. This covers requests even if access logging is off.

The output includes visitor IP addresses. Keep it out of the repo.

## When it was run, and why

Run on 2026-10-26, after the fix was deployed, to find out whether anyone had
used the endpoints without authorization before the fix.

HTTPS requests are logged to `other_vhosts_access.log`, which is rotated daily
and kept for 14 days. The earliest entry was from 2026-10-12, so the endpoints'
history before that (back to 2016) can't be checked. Within the window, there
were no requests to the CSV or reorder endpoints except a check made after the
deploy, which got a 401. The only requests to the question-JSON endpoint came
from a staff member's browser.

(README written by Claude Code.)
