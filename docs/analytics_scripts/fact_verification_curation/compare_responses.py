#!/usr/bin/env python3
"""Compare student fact-verification responses against the team's hand checks.

    python3 compare_responses.py fv_responses_2026-09-15.csv
    python3 compare_responses.py fv_responses.csv --min-responses 3 --served-only
    python3 compare_responses.py fv_responses.csv --since 2026-09-09T20:50Z

Takes the CSV that export_responses.rb produces on production and the team's
spreadsheet (default: ~/fact_verification_curation/, outside the repo because
it holds the reviewers' names), joins them on claim id, and
reports how often students reached the team's conclusion and which claims are
the worst hot spots.

Joining on claim id is safe because the spreadsheet's "Claim ID" column is
production's verification_claims.id -- the same ids config/claim_verification
_rollout.yml excludes by. The join is verified rather than trusted: article
titles are compared on every matched row and mismatches are reported, because a
silent id-space mismatch would make every number below meaningless.

Two mapping decisions are baked in, both reported rather than hidden:

1. "Source good?" is ambiguous -- the exercise asks two source questions
   (source_appropriate, "is this the right kind of source for this claim", and
   meets_rs_policy, "does it meet WP:RS"). Rather than pick one, both are
   scored against that column, which also shows which one the team's judgement
   tracks more closely.
2. Agreement is scored two ways. `exact` maps each team label to one student
   option. `binary` collapses to the distinction the exercise exists to teach
   -- fully supported vs anything less -- which is well-defined for the retired
   `mostly_*` verdicts too, where an exact mapping is not.

Spreadsheet cells left blank are dropped from denominators, not counted as
disagreements.

--since / --until window the responses by `submitted_at` (the response's
created_at, in UTC), so a run can be limited to the period after a change to
the exercise shipped. They filter on when the student answered, not on
`updated_at`, because the wording a student saw is fixed at answer time.
"""

import argparse
import collections
import csv
import datetime
import os
import sys

try:
    import openpyxl
except ImportError:
    sys.exit('Needs openpyxl: pip install openpyxl')

DEFAULT_XLSX = os.path.expanduser(
    '~/fact_verification_curation/Fall 2026 claim verification exercise data (1).xlsx')

# team label -> the student answers that count as agreeing with it
ACCESS = {'Yes': {'accessed'}, 'No': {'nonexistent', 'inaccessible'}}
VERDICT = {'Yes': {'full_support'}, 'Somewhat': {'partial_support'},
           'No': {'unsupported'}, 'Contradicts': {'contradicted'}}
SOURCE_GOOD = {
    'source_appropriate': {'Yes': {'appropriate'}, 'No': {'inappropriate'}},
    'meets_rs_policy': {'Yes': {'generally_reliable'}, 'No': {'not_reliable'}},
}
# Answers that are neither agreement nor disagreement with a Yes/No judgement:
# the student hedged where the team committed. Counted and reported apart.
HEDGES = {'depends_on_use', 'context_dependent', 'unsure', 'undetermined'}
# Verdicts the form no longer offers but older responses still carry. They have
# no exact counterpart among the team's labels -- "mostly" sits between Yes and
# Somewhat -- so scoring them as agreement or disagreement would be inventing a
# judgement. They are counted apart, and still scored on the binary axis below,
# where "not fully supported" is unambiguous for them.
RETIRED = {'mostly_supports', 'mostly_unsupported'}


def title_matches(sheet_title, export_title):
    """Whether a spreadsheet article name and an exported one are the same page.

    One name in the Fall 2026 sheet is stored truncated with an ellipsis
    ("History of immigration and nationality law in the United ..."), so an
    equality test reports 14 claims as an id-space mismatch when the join is
    perfectly fine. A truncated name is compared on the prefix it kept.
    """
    a = (sheet_title or '').replace(' ', '_').lower()
    b = (export_title or '').replace(' ', '_').lower()
    for ellipsis in ('...', '\u2026'):
        if a.endswith(ellipsis):
            return b.startswith(a[:-len(ellipsis)].rstrip('_'))
    return a == b


def pct(n, total):
    return '    -' if not total else '{:5.1f}%'.format(100.0 * n / total)


def load_team(path):
    """{claim_id: {'article', 'claim_no', 'multi', 'reviewer', 'access',
    'good', 'supports', 'notes'}}"""
    ws = openpyxl.load_workbook(path, data_only=True)['Sheet1']
    rows = list(ws.iter_rows(values_only=True))[1:]
    out = {}
    for r in rows:
        if r[2] is None:
            continue
        cell = lambda i: str(r[i]).strip() if r[i] is not None and str(r[i]).strip() else None
        out[int(r[2])] = {
            'article': cell(0), 'claim_no': r[1], 'multi': cell(3), 'reviewer': cell(4),
            'access': cell(5), 'good': cell(6), 'supports': cell(7), 'notes': cell(8),
        }
    return out


def parse_when(text):
    """A --since/--until value as a UTC datetime. Accepts a bare date or an
    ISO-8601 timestamp, with or without the trailing Z."""
    if text is None:
        return None
    raw = text.strip().replace('Z', '+00:00')
    try:
        when = datetime.datetime.fromisoformat(raw)
    except ValueError:
        sys.exit('Cannot read {!r} as a date or timestamp.'.format(text))
    if when.tzinfo is None:
        when = when.replace(tzinfo=datetime.timezone.utc)
    return when.astimezone(datetime.timezone.utc)


def submitted(row):
    return datetime.datetime.fromisoformat(row['submitted_at'].replace('Z', '+00:00'))


def load_responses(path, served_only, since=None, until=None):
    with open(path, newline='', encoding='utf-8') as f:
        rows = [r for r in csv.DictReader(f)]
    if served_only:
        rows = [r for r in rows if r.get('currently_served', '').lower() == 'true']
    if since:
        rows = [r for r in rows if submitted(r) >= since]
    if until:
        rows = [r for r in rows if submitted(r) < until]
    return rows


def score(rows, team, question, column, mapping):
    """Agreement on one question. Returns (agree, disagree, hedged, retired,
    pairs) where pairs is [(team_label, student_answer, row)] for all scored."""
    agree = disagree = hedged = retired = 0
    pairs = []
    for r in rows:
        t = team.get(int(r['claim_id']))
        if t is None or not t[column]:
            continue
        student = (r.get(question) or '').strip()
        if not student:
            continue
        pairs.append((t[column], student, r))
        if student in HEDGES:
            hedged += 1
        elif student in RETIRED:
            retired += 1
        elif student in mapping.get(t[column], set()):
            agree += 1
        else:
            disagree += 1
    return agree, disagree, hedged, retired, pairs


def heading(text):
    print('\n' + text)
    print('-' * len(text))


def main():
    p = argparse.ArgumentParser()
    p.add_argument('responses', help='CSV from export_responses.rb')
    p.add_argument('--spreadsheet', default=DEFAULT_XLSX)
    p.add_argument('--min-responses', type=int, default=2,
                   help='claims with at least this many scored responses lead the hot-spot list')
    p.add_argument('--served-only', action='store_true',
                   help='drop responses to claims the rollout no longer serves')
    p.add_argument('--since', help='only responses submitted at or after this UTC date/timestamp')
    p.add_argument('--until', help='only responses submitted before this UTC date/timestamp')
    args = p.parse_args()

    since, until = parse_when(args.since), parse_when(args.until)
    team = load_team(args.spreadsheet)
    rows = load_responses(args.responses, args.served_only, since, until)
    if not rows:
        sys.exit('No responses in that window.')

    # --- join health ---------------------------------------------------------
    heading('Window')
    stamps = sorted(submitted(r) for r in rows)
    print('  submitted between          {} and {}'.format(
        stamps[0].strftime('%Y-%m-%d %H:%M UTC'), stamps[-1].strftime('%Y-%m-%d %H:%M UTC')))
    if since or until:
        print('  requested                  {} to {}'.format(
            since.strftime('%Y-%m-%d %H:%M UTC') if since else 'start',
            until.strftime('%Y-%m-%d %H:%M UTC') if until else 'now'))
    print('  students                   {}'.format(len({r['user_id'] for r in rows})))
    print('  courses                    {}'.format(len({r['course_id'] for r in rows})))

    heading('Join')
    matched = [r for r in rows if int(r['claim_id']) in team]
    unmatched = [r for r in rows if int(r['claim_id']) not in team]
    print('  responses in export        {}'.format(len(rows)))
    print('  matched a checked claim    {}  {}'.format(len(matched), pct(len(matched), len(rows))))
    print('  no row in the spreadsheet  {}'.format(len(unmatched)))
    if unmatched:
        ids = sorted({int(r['claim_id']) for r in unmatched})
        print('    claim ids: {}{}'.format(', '.join(str(i) for i in ids[:12]),
                                           ' ...' if len(ids) > 12 else ''))
    print('  claims checked by the team {}'.format(len(team)))
    print('  of those, any response     {}'.format(
        len({int(r['claim_id']) for r in matched})))

    # A title mismatch means the two sides are not the same id space. Every
    # number after this point would be meaningless, so it is checked, not assumed.
    bad = [r for r in matched
           if team[int(r['claim_id'])]['article']
           and not title_matches(team[int(r['claim_id'])]['article'], r['claim_article_title'])]
    if bad:
        print('\n  !! {} rows where the article title disagrees with the spreadsheet.'.format(len(bad)))
        print('     The claim ids are not the same id space -- stop and check the export.')
        seen = set()
        for r in bad:
            if r['claim_id'] in seen:
                continue
            seen.add(r['claim_id'])
            print('     claim {}: export {!r} vs sheet {!r}'.format(
                r['claim_id'], r['claim_article_title'], team[int(r['claim_id'])]['article']))
            if len(seen) == 5:
                break
    else:
        print('  article titles agree       yes (join verified)')

    if not matched:
        sys.exit('\nNothing to compare.')

    # --- agreement per question ---------------------------------------------
    checks = [('Did the student get the source? (Access source?)', 'source_access', 'access', ACCESS),
              ('Is the source good? vs source_appropriate', 'source_appropriate', 'good',
               SOURCE_GOOD['source_appropriate']),
              ('Is the source good? vs meets_rs_policy', 'meets_rs_policy', 'good',
               SOURCE_GOOD['meets_rs_policy']),
              ('Does the source support the claim? (Supports claim?)', 'verdict', 'supports', VERDICT)]

    for label, question, column, mapping in checks:
        agree, disagree, hedged, retired, pairs = score(matched, team, question, column, mapping)
        scored = agree + disagree
        heading(label)
        print('  responses compared   {}'.format(len(pairs)))
        print('  agreed               {}  {} of the {} decisive'.format(agree, pct(agree, scored), scored))
        print('  disagreed            {}  {}'.format(disagree, pct(disagree, scored)))
        print('  student hedged       {}  (no yes/no to compare)'.format(hedged))
        if retired:
            print('  retired option       {}  (no exact counterpart; see binary below)'.format(retired))

        if question == 'verdict':
            # The distinction the exercise teaches: clean claim vs not. Defined
            # for the retired mostly_* verdicts, which have no exact mapping.
            b_agree = b_total = 0
            for t_label, student, _r in pairs:
                if student in HEDGES:
                    continue  # retired verdicts DO score here -- that is the point
                b_total += 1
                if (t_label == 'Yes') == (student == 'full_support'):
                    b_agree += 1
            print('  fully-supported-or-not agreement  {}  {}'.format(b_agree, pct(b_agree, b_total)))

        # Where they diverge, in both directions.
        matrix = collections.Counter((t, s) for t, s, _r in pairs)
        if matrix:
            print('\n  team answer      student answer          n')
            for (t_label, student), n in sorted(matrix.items(), key=lambda kv: -kv[1]):
                if student in mapping.get(t_label, set()):
                    flag = ''
                elif student in HEDGES:
                    flag = '  (hedge)'
                elif student in RETIRED:
                    flag = '  (retired)'
                else:
                    flag = '  <-- mismatch'
                print('  {:<16} {:<22} {:>4}{}'.format(t_label, student, n, flag))

    # --- what students do with each kind of claim ----------------------------
    #
    # The single most decision-relevant view. A flat agreement rate hides the
    # asymmetry that matters: the exercise exists to teach students to catch
    # cited text that its source does not support, so missing a bad claim and
    # over-flagging a good one are not the same failure. "flagged" is the share
    # who called the claim anything short of fully supported -- the judgement
    # the exercise is really training, and the one that survives the retired
    # `mostly_*` verdicts intact.
    heading('What students concluded, by what the team concluded')
    by_team = collections.defaultdict(collections.Counter)
    *_counts, pairs = score(matched, team, 'verdict', 'supports', VERDICT)
    for t_label, student, _r in pairs:
        by_team[t_label][student] += 1

    print('  {:<13} {:>5} {:>8} {:>9}   {}'.format(
        'team said', 'n', 'exact', 'flagged', 'most common student answers'))
    for t_label in ['Yes', 'Somewhat', 'No', 'Contradicts']:
        counts = by_team.get(t_label)
        if not counts:
            continue
        n = sum(counts.values())
        exact = sum(counts[a] for a in VERDICT[t_label])
        flagged = sum(v for k, v in counts.items()
                      if k != 'full_support' and k not in HEDGES)
        print('  {:<13} {:>5} {:>7} {:>8}   {}'.format(
            t_label, n, pct(exact, n).strip(), pct(flagged, n).strip(),
            ', '.join('{} x{}'.format(k, v) for k, v in counts.most_common(3))))

    missed = {t: c for t, c in by_team.items() if t in ('Somewhat', 'No', 'Contradicts')}
    bad_n = sum(sum(c.values()) for c in missed.values())
    bad_caught = sum(v for c in missed.values() for k, v in c.items()
                     if k != 'full_support' and k not in HEDGES)
    good_n = sum(by_team.get('Yes', {}).values())
    good_ok = by_team.get('Yes', collections.Counter())['full_support']
    if bad_n and good_n:
        print('\n  team judged the claim less than fully supported: '
              '{} responses, {} flagged it {}'.format(bad_n, bad_caught, pct(bad_caught, bad_n)))
        print('  team judged the claim fully supported:          '
              '{} responses, {} agreed {}'.format(good_n, good_ok, pct(good_ok, good_n)))

    # --- hot spots -----------------------------------------------------------
    per_claim = collections.defaultdict(lambda: {'n': 0, 'agree': 0, 'answers': collections.Counter()})
    *_counts, pairs = score(matched, team, 'verdict', 'supports', VERDICT)
    for t_label, student, r in pairs:
        if student in HEDGES or student in RETIRED:
            continue
        s = per_claim[int(r['claim_id'])]
        s['n'] += 1
        s['answers'][student] += 1
        if student in VERDICT.get(t_label, set()):
            s['agree'] += 1

    heading('Hot spots -- claims where students least often matched the team on the verdict')
    ranked = sorted(per_claim.items(), key=lambda kv: (kv[1]['agree'] / kv[1]['n'], -kv[1]['n']))
    shown = [(cid, s) for cid, s in ranked if s['n'] >= args.min_responses]
    if not shown:
        print('  No claim has {} or more scored responses yet.'.format(args.min_responses))
        shown = ranked
    for cid, s in shown[:25]:
        t = team[cid]
        claim_no = t['claim_no']
        if isinstance(claim_no, float) and claim_no.is_integer():
            claim_no = int(claim_no)
        print('\n  claim {}  {}  claim #{}'.format(cid, t['article'], claim_no))
        print('    team said {!r}; {} of {} students agreed  {}'.format(
            t['supports'], s['agree'], s['n'], pct(s['agree'], s['n'])))
        print('    students: {}'.format(', '.join(
            '{} x{}'.format(a, n) for a, n in s['answers'].most_common())))
        if t['multi']:
            print('    NOTE: spreadsheet marks this claim as having multiple citations')
        if t['notes']:
            print('    team note: {}'.format(t['notes'][:160]))
    print()


if __name__ == '__main__':
    main()
