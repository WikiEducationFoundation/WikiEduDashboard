"""Phase 2 of PLAN.md: non-LLM quality signals per course-article.

Reads the bundles written by phase2_fetch.rb (data/phase2/bundles) and writes
data/phase2_article_metrics.csv and wcp_analysis.phase2_article_metrics, one
row per course-article:

  deleted / redirected   page gone, or now a redirect
  new_article            the class created the page
  words_added            words in 5-word shingles new at end of window
  class_byte_share       share of in-window bytes added by enrolled students
  survival_f180 / _now   share of added shingles still present 180 days after
                         the window / today
  refs_added             <ref> tags added in the window (named reuses excluded)
  refs_per_kword         refs_added per 1,000 words added
  student_revs           student revisions in the window
  student_revs_reverted  of those, reverted within 30 days (identity revert by
                         sha1, or the mw-reverted tag)
  reverted_by_other      of those, reverted by someone outside the class
  student_bytes_reverted bytes added by reverted student revisions
  inline_tags_added_during / _after   inline problem tags ({{citation
                         needed}}, {{failed verification}}, ...) new in the
                         window / new between end of window and f180
  banner_tags_added_during / _after   the same for article/section cleanup
                         banners ({{essay-like}}, {{original research}}, ...)
  quality_baseline / quality_end      LiftWing expected quality (Stub=0 .. FA=5)
  quality_delta          end minus baseline (baseline 0 for new articles)
"""
import collections
import csv
import glob
import gzip
import json
import os
import re
import subprocess
from datetime import datetime, timedelta

HERE = os.path.dirname(os.path.abspath(__file__))
BUNDLES = os.path.join(HERE, 'data/phase2/bundles')
OUT_CSV = os.path.join(HERE, 'data/phase2_article_metrics.csv')
DB = ['mysql', '--no-defaults', '-u', 'wiki', '-pwikiedu', '-h', '127.0.0.1', 'wcp_analysis']

SHINGLE = 5
REVERT_WINDOW = timedelta(days=30)
REVERT_LOOKAHEAD = 30  # revisions
QUALITY_CLASSES = {'Stub': 0, 'Start': 1, 'C': 2, 'B': 3, 'GA': 4, 'FA': 5}

INLINE_TAGS = ['citation needed', 'cn', 'fact', 'failed verification', 'dubious', 'better source needed',
               'better source', 'verification needed', 'clarify', 'vague', 'according to whom', 'by whom',
               'who', 'when', 'weasel inline', 'peacock inline', 'original research inline', 'or inline',
               'unreliable source?', 'self-published inline', 'page needed', 'full citation needed',
               'citation needed span', 'irrelevant citation', 'text-source integrity?', 'synthesis inline']
BANNER_TAGS = ['more citations needed', 'refimprove', 'unreferenced', 'unreferenced section',
               'more citations needed section', 'refimprove section', 'original research', 'essay-like',
               'essay', 'tone', 'peacock', 'puffery', 'advert', 'npov', 'pov', 'pov section', 'copy edit',
               'copyedit', 'cleanup', 'cleanup rewrite', 'primary sources', 'third-party', 'one source',
               'close paraphrasing', 'copypaste', 'copyvio', 'synthesis', 'lead too short', 'overly detailed',
               'too long', 'textbook', 'how-to', 'fansite', 'weasel', 'multiple issues', 'ai-generated',
               'ai generated', 'llm', 'self-published', 'citation style', 'disputed', 'globalize',
               'expert needed', 'confusing', 'technical', 'undue weight', 'fringe theories']
TEMPLATE_RE = re.compile(r'\{\{\s*([^{}|]+?)\s*(?:\||\}\})')
REF_RE = re.compile(r'<ref(?:\s[^>]*)?>', re.I)  # opening, not self-closing reuse
WORD_RE = re.compile(r'[a-z0-9]+')


def ts(value):
    return datetime.strptime(value, '%Y-%m-%dT%H:%M:%SZ')


def shingles(text):
    words = WORD_RE.findall((text or '').lower())
    return set(tuple(words[i:i + SHINGLE]) for i in range(max(len(words) - SHINGLE + 1, 0)))


def templates(text, names):
    wanted = set(names)
    found = collections.Counter()
    for match in TEMPLATE_RE.finditer(text or ''):
        name = match.group(1).strip().lower().replace('_', ' ')
        if name in wanted:
            found[name] += 1
    return found


def new_count(before, after):
    return sum((after - before).values())


def expected_quality(score):
    if not score or 'probability' not in score:
        return None
    return round(sum(QUALITY_CLASSES.get(k, 0) * p for k, p in score['probability'].items()), 3)


def revert_stats(revs, pre_sha1):
    stats = collections.Counter()
    for i, rev in enumerate(revs):
        if rev['role'] != 'student':
            continue
        stats['student_revs'] += 1
        prior_sha1 = revs[i - 1].get('sha1') if i else pre_sha1
        reverted_by = None
        if 'mw-reverted' in (rev.get('tags') or []):
            reverted_by = 'tag'
        limit = ts(rev['timestamp']) + REVERT_WINDOW
        for later in revs[i + 1:i + 1 + REVERT_LOOKAHEAD]:
            if ts(later['timestamp']) > limit:
                break
            if prior_sha1 and later.get('sha1') == prior_sha1:
                reverted_by = later['role']
                break
        if reverted_by:
            stats['student_revs_reverted'] += 1
            stats['student_bytes_reverted'] += max(rev['delta'], 0)
            if reverted_by == 'other':
                stats['reverted_by_other'] += 1
    return stats


def metrics(bundle):
    row = {'course_id': bundle['course_id'], 'page_id': bundle['page_id'],
           'title': bundle.get('title') or bundle.get('dashboard_title'),
           'dashboard_characters': bundle['character_sum'], 'deleted': bool(bundle.get('missing'))}
    if row['deleted']:
        return row
    revs = bundle['revisions']
    prev = (bundle.get('pre_window_rev') or {}).get('size', 0)
    for rev in revs:
        rev['delta'] = rev.get('size', 0) - prev
        prev = rev.get('size', 0)
    window_end = ts(bundle['window_end'])
    in_window = [r for r in revs if ts(r['timestamp']) <= window_end]
    snaps = bundle.get('snapshots', {})
    text = {k: (v or {}).get('text') for k, v in snaps.items()}
    first_student = next((r for r in revs if r['role'] == 'student'), None)
    row['new_article'] = bool(first_student and first_student.get('parentid') == 0)
    baseline = '' if row['new_article'] else text.get('baseline')
    row['redirected'] = (text.get('current') or '').lstrip().lower().startswith('#redirect')
    row['has_baseline'] = baseline is not None
    row['f180_reached'] = bundle['f180_reached']

    student_bytes = sum(max(r['delta'], 0) for r in in_window if r['role'] == 'student')
    all_bytes = sum(max(r['delta'], 0) for r in in_window)
    row['class_byte_share'] = round(student_bytes / all_bytes, 3) if all_bytes else None
    row['student_bytes_added'] = student_bytes
    row.update(revert_stats(revs, (bundle.get('pre_window_rev') or {}).get('sha1')))
    for key in ('student_revs', 'student_revs_reverted', 'reverted_by_other', 'student_bytes_reverted'):
        row.setdefault(key, 0)

    if baseline is not None and text.get('end') is not None:
        added = shingles(text['end']) - shingles(baseline)
        row['words_added'] = len(added)
        if added:
            if text.get('f180') is not None:
                row['survival_f180'] = round(len(added & shingles(text['f180'])) / len(added), 3)
            if text.get('current') is not None and not row['redirected']:
                row['survival_now'] = round(len(added & shingles(text['current'])) / len(added), 3)
            elif row['redirected']:
                row['survival_now'] = 0.0
        refs = len(REF_RE.findall(text['end'])) - len(REF_RE.findall(baseline))
        row['refs_added'] = refs
        row['refs_per_kword'] = round(1000 * refs / len(added), 2) if len(added) >= 100 else None
        for kind, names in (('inline', INLINE_TAGS), ('banner', BANNER_TAGS)):
            base_t, end_t = templates(baseline, names), templates(text['end'], names)
            row[f'{kind}_tags_added_during'] = new_count(base_t, end_t)
            if text.get('f180') is not None:
                row[f'{kind}_tags_added_after'] = new_count(end_t, templates(text['f180'], names))

    quality = bundle.get('quality') or {}
    q_end = expected_quality(quality.get('end'))
    q_base = 0.0 if row['new_article'] else expected_quality(quality.get('baseline'))
    row['quality_baseline'], row['quality_end'] = q_base, q_end
    row['quality_delta'] = round(q_end - q_base, 3) if q_end is not None and q_base is not None else None
    return row


COLUMNS = ['course_id', 'page_id', 'title', 'dashboard_characters', 'deleted', 'redirected',
           'new_article', 'has_baseline', 'f180_reached', 'words_added', 'student_bytes_added',
           'class_byte_share', 'survival_f180', 'survival_now', 'refs_added', 'refs_per_kword',
           'student_revs', 'student_revs_reverted', 'reverted_by_other', 'student_bytes_reverted',
           'inline_tags_added_during', 'inline_tags_added_after', 'banner_tags_added_during',
           'banner_tags_added_after', 'quality_baseline', 'quality_end', 'quality_delta']
SQL_TYPES = {'title': 'VARCHAR(512)', 'deleted': 'BOOLEAN', 'redirected': 'BOOLEAN', 'new_article': 'BOOLEAN',
             'has_baseline': 'BOOLEAN', 'f180_reached': 'BOOLEAN', 'class_byte_share': 'FLOAT',
             'survival_f180': 'FLOAT', 'survival_now': 'FLOAT', 'refs_per_kword': 'FLOAT',
             'quality_baseline': 'FLOAT', 'quality_end': 'FLOAT', 'quality_delta': 'FLOAT'}


def sql_value(value):
    if value is None:
        return 'NULL'
    if isinstance(value, bool):
        return '1' if value else '0'
    if isinstance(value, (int, float)):
        return str(value)
    return "'" + str(value).replace('\\', '\\\\').replace("'", "''") + "'"


def main():
    rows = []
    for path in sorted(glob.glob(os.path.join(BUNDLES, '*.json.gz'))):
        try:
            with gzip.open(path) as f:
                bundle = json.load(f)
        except (EOFError, OSError, ValueError):
            continue  # still being written
        rows.append(metrics(bundle))
    with open(OUT_CSV, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=COLUMNS, extrasaction='ignore')
        writer.writeheader()
        writer.writerows(rows)
    ddl = ', '.join(f'`{c}` {SQL_TYPES.get(c, "INT")}' for c in COLUMNS)
    sql = ['DROP TABLE IF EXISTS phase2_article_metrics;',
           f'CREATE TABLE phase2_article_metrics ({ddl}, INDEX (course_id));']
    for row in rows:
        sql.append('INSERT INTO phase2_article_metrics VALUES (%s);'
                   % ', '.join(sql_value(row.get(c)) for c in COLUMNS))
    subprocess.run(DB, input='\n'.join(sql), text=True, check=True)
    print(f'{len(rows)} course-articles -> {OUT_CSV} and wcp_analysis.phase2_article_metrics')


if __name__ == '__main__':
    main()
