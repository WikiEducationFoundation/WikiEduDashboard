import React from 'react';
import PropTypes from 'prop-types';
import SandboxPreview, { usePagePreview } from './SandboxPreview';
import { StageTracker } from './ArticleParts';
import {
  articleStatusLabel, formatDate, isLate, percent, stateLabel
} from './assignmentHelpers';

const ExternalLink = ({ href, children }) => (
  <a href={href} target="_blank" rel="noopener noreferrer">{children}</a>
);

ExternalLink.propTypes = { href: PropTypes.string.isRequired, children: PropTypes.node };

const OverdueFlag = () => (
  <span className="assignments-tab__overdue">{I18n.t('assignments_tab.overdue')}</span>
);

// A cell's status word, with the overdue flag beside it.
export const StateBadge = ({ cell }) => (
  <span className={`assignments-tab__state assignments-tab__state--${cell.state}`}>
    {stateLabel(cell.state)}
    {cell.overdue && <OverdueFlag />}
  </span>
);

StateBadge.propTypes = { cell: PropTypes.object.isRequired };

// A page the student works on, with whether it exists yet and, outside the
// compact roster, a toggle to read it here.
const PageLink = ({ label, url, created, preview }) => (
  <>
    <ExternalLink href={url}>{label}</ExternalLink>
    {created !== undefined && (
      <>
        {': '}
        {created
          ? I18n.t('lti.assignment_view.article_work.created')
          : I18n.t('lti.assignment_view.article_work.not_created_yet')}
      </>
    )}
    {preview && <>{' '}<SandboxPreview url={url} /></>}
  </>
);

PageLink.propTypes = {
  label: PropTypes.node.isRequired,
  url: PropTypes.string.isRequired,
  created: PropTypes.bool,
  preview: PropTypes.bool,
};

// When a module was finished, flagged if after its due date; else how far
// through the slides the student is.
const TrainingProgress = ({ cell, item }) => {
  if (cell.completed_at) {
    return (
      <span>
        {formatDate(cell.completed_at)}
        {isLate(cell.completed_at, item.due_date) && (
          <span className="assignments-tab__late"> ({I18n.t('training_status.late')})</span>
        )}
      </span>
    );
  }
  if (cell.slide_progress) {
    return <span>{percent(cell.slide_progress)} {I18n.t('training_status.completed')}</span>;
  }
  return null;
};

TrainingProgress.propTypes = { cell: PropTypes.object.isRequired, item: PropTypes.object.isRequired };

const PAGE_LABELS = {
  bibliography: 'lti.assignment_view.article_work.pages.bibliography',
  outline: 'lti.assignment_view.article_work.pages.outline',
  draft: 'lti.assignment_view.article_work.pages.draft',
};

// A done / not-done marker with its word, so state never rests on color.
const Status = ({ done, children }) => (
  <span className={`assignments-tab__status assignments-tab__status--${done ? 'done' : 'todo'}`}>
    <span className="assignments-tab__status-mark" aria-hidden="true">{done ? '✓' : '○'}</span>
    {children}
  </span>
);

Status.propTypes = { done: PropTypes.bool, children: PropTypes.node };

// One row of a work table: what it is, its state, and actions in fixed
// columns, so the links and Show buttons line up down the table. A preview
// opens in a full-width row beneath.
const WorkRow = ({ label, detail, url, preview }) => {
  const { open, button, panel } = usePagePreview(url);
  return (
    <>
      <tr>
        <th scope="row">{label}</th>
        <td>{detail}</td>
        <td className="assignments-tab__work-actions">
          <ExternalLink href={url}>{I18n.t('lti.assignment_view.open_on_wikipedia')}</ExternalLink>
          {preview && button}
        </td>
      </tr>
      {preview && (
        <tr className="assignments-tab__preview-row" hidden={!open}>
          <td colSpan={3}>{panel}</td>
        </tr>
      )}
    </>
  );
};

WorkRow.propTypes = {
  label: PropTypes.node.isRequired,
  detail: PropTypes.node,
  url: PropTypes.string.isRequired,
  preview: PropTypes.bool,
};

const LiveStats = ({ stats }) => (
  <span className="assignments-tab__live-stats">
    {[['characters', stats.characters], ['references', stats.references], ['revisions', stats.revisions]]
      .map(([key, value]) => (
        <span key={key}>
          {I18n.t(`lti.assignment_view.article_work.${key}`)} <strong>{value.toLocaleString()}</strong>
        </span>
      ))}
  </span>
);

LiveStats.propTypes = { stats: PropTypes.object.isRequired };

// One assigned article as a card: the article and when the student got it,
// how far along it is, then where the work is: each page and the live article,
// with its state, a link, and a preview to read it here.
const ArticleCard = ({ article }) => {
  const status = article.status_updated_at ? articleStatusLabel(article.status) : '';
  return (
    <section className="assignments-tab__card">
      <div className="assignments-tab__card-header">
        <div>
          <h5 className="assignments-tab__card-title">
            <ExternalLink href={article.url}>{article.title}</ExternalLink>
          </h5>
          {status && (
            <span className="assignments-tab__pill">
              {status} · {formatDate(article.status_updated_at)}
            </span>
          )}
        </div>
        {article.assigned_at && (
          <span className="assignments-tab__date">
            {I18n.t('assignments_tab.assigned')} {formatDate(article.assigned_at)}
          </span>
        )}
      </div>
      <StageTracker stages={article.stages} />
      <table className="assignments-tab__work-table">
        <tbody>
          {article.pages.map(page => (
            <WorkRow
              key={page.kind} label={I18n.t(PAGE_LABELS[page.kind])} url={page.url} preview
              detail={(
                <Status done={page.created}>
                  {I18n.t(page.created
                    ? 'lti.assignment_view.article_work.created'
                    : 'lti.assignment_view.article_work.not_created_yet')}
                </Status>
              )}
            />
          ))}
          <WorkRow
            label={I18n.t('assignments_tab.live_article')} url={article.url}
            detail={article.live
              ? <LiveStats stats={article.stats} />
              : <Status done={false}>{I18n.t('lti.assignment_view.article_work.not_created')}</Status>}
          />
        </tbody>
      </table>
    </section>
  );
};

ArticleCard.propTypes = { article: PropTypes.object.isRequired };

// The exercises about the article, as a checklist: done or not, when (where
// recorded) or overdue, and the exercise's sandbox to open or read here.
const ExerciseChecklist = ({ exercises }) => {
  if (!exercises.length) { return null; }
  return (
    <section className="assignments-tab__card">
      <div className="assignments-tab__card-header">
        <h5 className="assignments-tab__card-title">{I18n.t('lti.student_overview.exercises')}</h5>
      </div>
      <table className="assignments-tab__work-table">
        <tbody>
          {exercises.map((exercise) => {
            const detail = (
              <>
                <Status done={exercise.completed}>
                  {stateLabel(exercise.completed ? 'complete' : 'not_started')}
                  {exercise.completed_at && ` · ${formatDate(exercise.completed_at)}`}
                </Status>
                {exercise.overdue && <OverdueFlag />}
              </>
            );
            if (exercise.sandbox_url) {
              return (
                <WorkRow
                  key={exercise.slug} label={exercise.name} detail={detail}
                  url={exercise.sandbox_url} preview
                />
              );
            }
            return (
              <tr key={exercise.slug}>
                <th scope="row">{exercise.name}</th>
                <td>{detail}</td>
                <td />
              </tr>
            );
          })}
        </tbody>
      </table>
    </section>
  );
};

ExerciseChecklist.propTypes = { exercises: PropTypes.array.isRequired };

// The grader's view of the assigned article: a card per article, then the
// exercises about it. (The article panel shows it as ArticleRoster's table.)
const Article = ({ cell }) => (
  <div>
    {cell.articles.length === 0 && (
      <p className="assignments-tab__empty">{I18n.t('lti.assignment_view.no_article_yet')}</p>
    )}
    {cell.articles.map(article => <ArticleCard key={article.assignment_id} article={article} />)}
    <ExerciseChecklist exercises={cell.exercises} />
  </div>
);

Article.propTypes = { cell: PropTypes.object.isRequired };

const Reviews = ({ cell, compact }) => {
  const total = cell.expected || cell.reviews.length;
  return (
    <div className="assignments-tab__reviews">
      {total > 0 && (
        <p>
          {I18n.t('lti.assignment_view.peer_review.progress',
                  { completed: cell.completed_count, total })}
        </p>
      )}
      {cell.reviews.length === 0 && <p>{I18n.t('lti.assignment_view.peer_review.none_yet')}</p>}
      {!compact && cell.reviews.length > 0 && (
        <ul>
          {cell.reviews.map(review => (
            <li key={review.assignment_id}>
              <ExternalLink href={review.article_url}>{review.article_title}</ExternalLink>
              {' — '}
              <PageLink
                label={I18n.t('lti.assignment_view.peer_review.review_page')}
                url={review.review_url} preview
              />
              {': '}
              {stateLabel(review.completed ? 'complete' : 'not_started')}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
};

Reviews.propTypes = { cell: PropTypes.object.isRequired, compact: PropTypes.bool };

const Exercise = ({ cell, compact }) => (
  <div>
    {cell.completed_at && <p>{formatDate(cell.completed_at)}</p>}
    {cell.sandbox_url && (
      <p>
        <PageLink
          label={I18n.t('lti.assignment_view.roster.sandbox')} url={cell.sandbox_url}
          preview={!compact}
        />
      </p>
    )}
    {cell.article_title && (
      <p><ExternalLink href={cell.article_url}>{cell.article_title}</ExternalLink></p>
    )}
  </div>
);

Exercise.propTypes = { cell: PropTypes.object.isRequired, compact: PropTypes.bool };

// Everything known about one student's work on one assignment. `compact` is
// the roster's summary; the grader shows it in full, with sandbox previews.
const CellDetails = ({ cell, item, compact = false }) => {
  switch (item.kind) {
    case 'training':
      return <TrainingProgress cell={cell} item={item} />;
    case 'exercise':
      return <Exercise cell={cell} compact={compact} />;
    case 'article':
      return <Article cell={cell} />;
    case 'peer_review':
      return <Reviews cell={cell} compact={compact} />;
    default:
      return null;
  }
};

CellDetails.propTypes = {
  cell: PropTypes.object.isRequired,
  item: PropTypes.object.isRequired,
  compact: PropTypes.bool,
};

export default CellDetails;
