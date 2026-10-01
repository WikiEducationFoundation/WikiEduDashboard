import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { useSearchParams } from 'react-router-dom';
import Loading from '@components/common/loading.jsx';
import ArticleRoster from './ArticleRoster';
import { STAGE_LABELS } from './ArticleParts';
import { hasRealNames } from './StudentSort';
import { formatDate, itemTitle, listQuery, reachedStage } from './assignmentHelpers';

const ARTICLE_KEY = 'article';

// One stage as a bar: the share of the class that has reached it, labelled
// with the count and percentage, and its due date and overdue count where a
// timeline exercise gives it one. Clicking it lists the students who haven't
// reached it; clicking again clears that.
const FunnelBar = ({ stage, total, active, onSelect }) => {
  const percent = total ? Math.round((stage.reached / total) * 100) : 0;
  return (
    <li>
      <button
        type="button" className={`assignments-tab__funnel-bar${active ? ' active' : ''}`}
        aria-pressed={active} onClick={onSelect}
      >
        <span className="assignments-tab__funnel-label">{I18n.t(STAGE_LABELS[stage.key])}</span>
        <span className="assignments-tab__funnel-track" aria-hidden="true">
          <span className="assignments-tab__funnel-fill" style={{ width: `${percent}%` }} />
        </span>
        <span className="assignments-tab__funnel-value">{stage.reached} / {total} · {percent}%</span>
        <span className="assignments-tab__funnel-meta">
          {stage.due_date && I18n.t('training_status.due', { due_date: formatDate(stage.due_date) })}
          {stage.overdue > 0 && (
            <span className="assignments-tab__overdue">
              {I18n.t('assignments_tab.overdue')}: {stage.overdue}
            </span>
          )}
        </span>
      </button>
    </li>
  );
};

FunnelBar.propTypes = {
  stage: PropTypes.object.isRequired,
  total: PropTypes.number.isRequired,
  active: PropTypes.bool,
  onSelect: PropTypes.func.isRequired,
};

// The assigned article, set apart from the other assignments: how much of the
// class has reached each stage of the writing process, then (on request) each
// student's articles, stage by stage, with links to the work. Whether the
// student list is showing and which stage it's narrowed to live in the URL
// (?students=1&missing=<stage>), so the grader can step through the same
// students and come back.
const ArticlePanel = ({ data, itemData, loadItem, tabPath }) => {
  const [searchParams, setSearchParams] = useSearchParams();
  const showStudents = searchParams.get('students') === '1';
  const missing = searchParams.get('missing');
  const item = data.items.find(candidate => candidate.key === ARTICLE_KEY);
  const funnel = data.article_funnel;

  useEffect(() => {
    if (showStudents && !itemData) { loadItem(ARTICLE_KEY); }
  }, [showStudents]);

  if (!item || !funnel) { return null; }

  const update = (changes) => {
    const params = new URLSearchParams(searchParams);
    Object.entries(changes).forEach(([key, value]) => (value ? params.set(key, value) : params.delete(key)));
    setSearchParams(params, { replace: true });
  };
  const selectStage = key => update({ students: '1', missing: missing === key ? null : key });

  let students;
  if (showStudents) {
    if (itemData?.failed) {
      students = <p role="alert">{I18n.t('system_stats.errors.fetch_failed')}</p>;
    } else if (!itemData) {
      students = <Loading />;
    } else {
      const cellsByUser = Object.fromEntries(itemData.rows.map(cell => [cell.user_id, cell]));
      const shown = itemData.students
        .filter(student => !missing || !reachedStage(cellsByUser[student.id], missing));
      const query = listQuery(searchParams);
      students = (
        <>
          {missing && (
            <button type="button" className="button border small" onClick={() => update({ missing: null })}>
              {I18n.t('articles.filter.wiki_all')}
            </button>
          )}
          <ArticleRoster
            students={shown} cellsByUser={cellsByUser} showNames={hasRealNames(itemData.students)}
            studentPath={student => `${tabPath}/${ARTICLE_KEY}/${encodeURIComponent(student.username)}${query}`}
          />
        </>
      );
    }
  }

  return (
    <section className="assignments-tab__article-panel">
      <h3>{itemTitle(item)}</h3>
      <ul className="assignments-tab__funnel">
        {funnel.stages.map(stage => (
          <FunnelBar
            key={stage.key} stage={stage} total={funnel.total}
            active={missing === stage.key} onSelect={() => selectStage(stage.key)}
          />
        ))}
      </ul>
      <button
        type="button" className="assignments-tab__students-toggle"
        aria-expanded={showStudents} onClick={() => update({ students: showStudents ? null : '1', missing: null })}
      >
        {I18n.t('courses.students')}
        <span className="icon icon-arrow-toggle" aria-hidden="true" />
      </button>
      {students}
    </section>
  );
};

ArticlePanel.propTypes = {
  data: PropTypes.shape({ items: PropTypes.array, article_funnel: PropTypes.object }).isRequired,
  itemData: PropTypes.object,
  loadItem: PropTypes.func.isRequired,
  tabPath: PropTypes.string.isRequired,
};

export default ArticlePanel;
