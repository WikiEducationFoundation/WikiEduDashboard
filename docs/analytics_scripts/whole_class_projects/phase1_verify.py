"""Phase 1 of PLAN.md: page-history verification of collaboration mode.

From data/phase1_revisions.jsonl (written by phase1_page_histories.rb), for
each labeled course:

  active_students   enrolled students with any tracked edit (courses_users)
  hist_top1_share   share of active students who edited the single page with
                    the most student editors (mainspace or draft)
  hist_top3_share   share who edited any of the top 3 such pages
  hist_top_editors  student editors on that top page
  instructor_edits  instructor revisions on the top 3 pages in the window
  top3_student_bytes / top3_other_bytes  bytes added in the window

Writes wcp_analysis.course_history_verification and prints a cross-tab
against the LLM labels.
"""
import collections
import json
import subprocess

DB = ['mysql', '--no-defaults', '-u', 'wiki', '-pwikiedu', '-h', '127.0.0.1', '--batch', '--skip-column-names']


def query(sql):
    out = subprocess.run(DB + ['-e', sql], capture_output=True, text=True, check=True).stdout
    return [line.split('\t') for line in out.splitlines()]


ns = {(r[0], int(r[1])): int(r[2]) for r in query(
    "SELECT wiki, page_id, namespace FROM wcp_analysis.page_history_stats "
    "WHERE missing = 0 AND page_id IS NOT NULL")}
active = {int(r[0]): int(r[1]) for r in query(
    "SELECT course_id, SUM(role = 0 AND revision_count > 0) FROM wcp_sanitized.courses_users "
    "WHERE course_id IN (SELECT course_id FROM wcp_analysis.course_mode_labels) GROUP BY course_id")}
labels = {int(r[0]): r[1:] for r in query(
    "SELECT course_id, mode, confidence, pool FROM wcp_analysis.course_mode_labels")}

pages = collections.defaultdict(lambda: collections.defaultdict(lambda: {
    'students': set(), 'instructor_revs': 0, 'student_bytes': 0, 'other_bytes': 0}))
with open('data/phase1_revisions.jsonl') as f:
    for line in f:
        r = json.loads(line)
        if ns.get((r['wiki'], r['page_id'])) not in (0, 118):
            continue
        p = pages[r['course_id']][(r['wiki'], r['page_id'])]
        delta = max(r['delta'], 0)
        if r['role'] == 'student':
            p['students'].add(r['user'])
            p['student_bytes'] += delta
        elif r['role'] == 'instructor':
            p['instructor_revs'] += 1
            p['other_bytes'] += delta
        else:
            p['other_bytes'] += delta

rows = []
for cid in labels:
    top = sorted(pages[cid].values(), key=lambda p: -len(p['students']))[:3]
    n = active.get(cid, 0)
    union = set().union(*(p['students'] for p in top)) if top else set()
    rows.append(dict(
        course_id=cid, active_students=n,
        hist_top_editors=len(top[0]['students']) if top else 0,
        hist_top1_share=round(len(top[0]['students']) / n, 3) if top and n else None,
        hist_top3_share=round(len(union) / n, 3) if n else None,
        instructor_edits=sum(p['instructor_revs'] for p in top),
        top3_student_bytes=sum(p['student_bytes'] for p in top),
        top3_other_bytes=sum(p['other_bytes'] for p in top)))

cols = list(rows[0].keys())
sql = ['DROP TABLE IF EXISTS wcp_analysis.course_history_verification;',
       'CREATE TABLE wcp_analysis.course_history_verification (course_id INT PRIMARY KEY, '
       'active_students INT, hist_top_editors INT, hist_top1_share FLOAT, hist_top3_share FLOAT, '
       'instructor_edits INT, top3_student_bytes INT, top3_other_bytes INT);']
for r in rows:
    vals = ', '.join('NULL' if r[c] is None else str(r[c]) for c in cols)
    sql.append(f'INSERT INTO wcp_analysis.course_history_verification VALUES ({vals});')
subprocess.run(DB, input='\n'.join(sql), text=True, check=True)


def bucket(r):
    s = r['hist_top3_share']
    if s is None or r['active_students'] < 5:
        return 'too_few_active'
    return '>=.6' if s >= 0.6 else '.3-.6' if s >= 0.3 else '<.3'


buckets = ['>=.6', '.3-.6', '<.3', 'too_few_active']
print('share of active students on top-3 shared pages, by LLM label')
print('%-24s' % 'label', ' '.join('%14s' % b for b in buckets))
by = collections.defaultdict(collections.Counter)
for r in rows:
    mode, conf, pool = labels[r['course_id']]
    key = f'{mode}/{conf}' if mode == 'whole_class' else mode
    by[key][bucket(r)] += 1
for key in sorted(by):
    print('%-24s' % key, ' '.join('%14d' % by[key][b] for b in buckets))
wc = [r for r in rows if labels[r['course_id']][0] == 'whole_class']
print('\nwhole_class courses with instructor edits on the shared pages:',
      sum(r['instructor_edits'] > 0 for r in wc), 'of', len(wc))
print('all labeled courses with instructor edits on top pages:', sum(r['instructor_edits'] > 0 for r in rows))
