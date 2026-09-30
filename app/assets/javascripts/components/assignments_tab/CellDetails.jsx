import React from 'react';
import PropTypes from 'prop-types';
import SandboxPreview from './SandboxPreview';
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

const LiveStats = ({ stats }) => (
  <dl className="assignments-tab__stats">
    <dt>{I18n.t('lti.assignment_view.article_work.characters')}</dt>
    <dd>{stats.characters}</dd>
    <dt>{I18n.t('lti.assignment_view.article_work.references')}</dt>
    <dd>{stats.references}</dd>
    <dt>{I18n.t('lti.assignment_view.article_work.revisions')}</dt>
    <dd>{stats.revisions}</dd>
  </dl>
);

LiveStats.propTypes = { stats: PropTypes.object.isRequired };

// One assigned article: what it is, where the student says they are with it,
// its bibliography/outline/draft pages, and what they've written live.
const ArticleWork = ({ article, compact }) => {
  const status = article.status_updated_at ? articleStatusLabel(article.status) : '';
  return (
    <div className="assignments-tab__article">
      <p className="assignments-tab__article-title">
        <ExternalLink href={article.url}>{article.title}</ExternalLink>
        {status && (
          <span className="assignments-tab__article-status">
            {' '}{status} ({formatDate(article.status_updated_at)})
          </span>
        )}
      </p>
      {compact ? (
        <p className="assignments-tab__pages--inline">
          {article.pages.map((page, index) => (
            <span key={page.kind}>
              {index > 0 && ' · '}
              <PageLink label={I18n.t(PAGE_LABELS[page.kind])} url={page.url} created={page.created} />
            </span>
          ))}
        </p>
      ) : (
        <ul className="assignments-tab__pages">
          {article.pages.map(page => (
            <li key={page.kind}>
              <PageLink
                label={I18n.t(PAGE_LABELS[page.kind])} url={page.url} created={page.created} preview
              />
            </li>
          ))}
        </ul>
      )}
      {article.live && <LiveStats stats={article.stats} />}
      {!article.live && !compact && <p>{I18n.t('lti.assignment_view.article_work.not_created')}</p>}
    </div>
  );
};

ArticleWork.propTypes = { article: PropTypes.object.isRequired, compact: PropTypes.bool };

// The exercises about the article: a count in the roster, a checklist in the
// grader with when each was done (where recorded) and its sandbox.
const ArticleExercises = ({ exercises, compact }) => {
  if (!exercises.length) { return null; }
  const heading = I18n.t('lti.student_overview.exercises');
  if (compact) {
    const done = exercises.filter(exercise => exercise.completed).length;
    return <p className="assignments-tab__exercise-count">{heading}: {done} / {exercises.length}</p>;
  }
  return (
    <div className="assignments-tab__exercises">
      <h5>{heading}</h5>
      <ul>
        {exercises.map(exercise => (
          <li key={exercise.slug}>
            <span className={`assignments-tab__state assignments-tab__state--${exercise.completed ? 'complete' : 'not_started'}`}>
              {stateLabel(exercise.completed ? 'complete' : 'not_started')}
            </span>
            {' '}{exercise.name}
            {exercise.completed_at && ` (${formatDate(exercise.completed_at)})`}
            {exercise.overdue && <OverdueFlag />}
            {exercise.sandbox_url && (
              <>
                {' · '}
                <PageLink label={I18n.t('lti.assignment_view.roster.sandbox')} url={exercise.sandbox_url} preview />
              </>
            )}
          </li>
        ))}
      </ul>
    </div>
  );
};

ArticleExercises.propTypes = { exercises: PropTypes.array.isRequired, compact: PropTypes.bool };

const Article = ({ cell, compact }) => (
  <div>
    {cell.articles.length === 0 && <p>{I18n.t('lti.assignment_view.no_article_yet')}</p>}
    {cell.articles.map(article => (
      <ArticleWork key={article.assignment_id} article={article} compact={compact} />
    ))}
    <ArticleExercises exercises={cell.exercises} compact={compact} />
  </div>
);

Article.propTypes = { cell: PropTypes.object.isRequired, compact: PropTypes.bool };

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
      return <Article cell={cell} compact={compact} />;
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
