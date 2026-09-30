import React from 'react';
import PropTypes from 'prop-types';
import {
  articleStatusLabel, formatDate, isLate, percent, stateLabel
} from './assignmentHelpers';

const ExternalLink = ({ href, children }) => (
  <a href={href} target="_blank" rel="noopener noreferrer">{children}</a>
);

ExternalLink.propTypes = { href: PropTypes.string.isRequired, children: PropTypes.node };

// A cell's status word, with the overdue flag beside it.
export const StateBadge = ({ cell }) => (
  <span className={`assignments-tab__state assignments-tab__state--${cell.state}`}>
    {stateLabel(cell.state)}
    {cell.overdue && (
      <span className="assignments-tab__overdue">{I18n.t('assignments_tab.overdue')}</span>
    )}
  </span>
);

StateBadge.propTypes = { cell: PropTypes.object.isRequired };

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

// One assigned article's work. `compact` (the roster) shows just the article
// and the page this assignment is about; the grader shows everything.
export const ArticleWork = ({ article, stage, compact }) => {
  const pages = compact ? article.pages.filter(page => page.kind === stage) : article.pages;
  const status = articleStatusLabel(article.status);
  const showStats = !compact || stage === 'live';
  return (
    <div className="assignments-tab__article">
      <p className="assignments-tab__article-title">
        <ExternalLink href={article.url}>{article.title}</ExternalLink>
        {!compact && status && (
          <span className="assignments-tab__article-status">
            {' '}{status}
            {article.status_updated_at && ` (${formatDate(article.status_updated_at)})`}
          </span>
        )}
      </p>
      {pages.length > 0 && (
        <ul className="assignments-tab__pages">
          {pages.map(page => (
            <li key={page.kind}>
              <ExternalLink href={page.url}>{I18n.t(PAGE_LABELS[page.kind])}</ExternalLink>
              {': '}
              {page.created
                ? I18n.t('lti.assignment_view.article_work.created')
                : I18n.t('lti.assignment_view.article_work.not_created_yet')}
            </li>
          ))}
        </ul>
      )}
      {showStats && !article.live && !compact && (
        <p>{I18n.t('lti.assignment_view.article_work.not_created')}</p>
      )}
      {showStats && article.live && (
        <dl className="assignments-tab__stats">
          <dt>{I18n.t('lti.assignment_view.article_work.characters')}</dt>
          <dd>{article.stats.characters}</dd>
          <dt>{I18n.t('lti.assignment_view.article_work.references')}</dt>
          <dd>{article.stats.references}</dd>
          <dt>{I18n.t('lti.assignment_view.article_work.revisions')}</dt>
          <dd>{article.stats.revisions}</dd>
        </dl>
      )}
    </div>
  );
};

ArticleWork.propTypes = {
  article: PropTypes.object.isRequired,
  stage: PropTypes.string,
  compact: PropTypes.bool,
};

const Articles = ({ articles, stage, compact }) => {
  if (!articles.length) { return <p>{I18n.t('lti.assignment_view.no_article_yet')}</p>; }
  return articles.map(article => (
    <ArticleWork key={article.assignment_id} article={article} stage={stage} compact={compact} />
  ));
};

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
              <ExternalLink href={review.review_url}>
                {I18n.t('lti.assignment_view.peer_review.review_page')}
              </ExternalLink>
              {': '}
              {stateLabel(review.completed ? 'complete' : 'not_started')}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
};

const Exercise = ({ cell, item, compact }) => (
  <div>
    {cell.completed_at && <p>{formatDate(cell.completed_at)}</p>}
    {cell.sandbox_url && (
      <p>
        <ExternalLink href={cell.sandbox_url}>{I18n.t('lti.assignment_view.roster.sandbox')}</ExternalLink>
      </p>
    )}
    {cell.article_title && (
      <p><ExternalLink href={cell.article_url}>{cell.article_title}</ExternalLink></p>
    )}
    {cell.articles && <Articles articles={cell.articles} stage={item.article_stage} compact={compact} />}
  </div>
);

// Everything known about one student's work on one assignment.
const CellDetails = ({ cell, item, compact = false }) => {
  switch (item.kind) {
    case 'training':
      return <TrainingProgress cell={cell} item={item} />;
    case 'exercise':
      return <Exercise cell={cell} item={item} compact={compact} />;
    case 'article':
      return <Articles articles={cell.articles} stage={item.article_stage} compact={compact} />;
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
