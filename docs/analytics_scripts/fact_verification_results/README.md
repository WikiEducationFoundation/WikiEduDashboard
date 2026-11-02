# Fact Verification: how students are answering

`summary.rb` prints a summary of the Fact Verification exercise: take-up
(responses, students, courses, claims), how students answered each question,
and which claims they picked. `summary_console.rb` is the same summary as a
`fv_summary` method to paste into a Rails console.

```bash
bundle exec rails runner docs/analytics_scripts/fact_verification_results/summary.rb
CAMPAIGN=fall_2026 bundle exec rails runner docs/analytics_scripts/fact_verification_results/summary.rb
NOTES=1 bundle exec rails runner docs/analytics_scripts/fact_verification_results/summary.rb
```

It was written in September 2026, early in the exercise's first full term, to
see how it was going. It reads the questions from
`ClaimVerification::ExerciseForm`, so it keeps up with changes to
`config/claim_verification_exercise.yml` without edits. Each question is
tallied only over the students who were asked it, and retired options, such
as the `mostly_*` verdicts, are reported separately.

It prints to the terminal and writes no files. `NOTES=1` adds the free-text
answers, which are student writing: don't save that output in the repo.

To compare students' answers with the team's hand checks of the same claims,
see `../fact_verification_curation/`.

(README written by Claude Code.)
