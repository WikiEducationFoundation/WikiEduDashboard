import React from 'react';
import PropTypes from 'prop-types';
import { stateLabel } from './assignmentHelpers';

export const STAGE_LABELS = {
  assigned: 'assignments_tab.stage_assigned',
  bibliography: 'lti.assignment_view.article_work.pages.bibliography',
  outline: 'lti.assignment_view.article_work.pages.outline',
  draft: 'lti.assignment_view.article_work.pages.draft',
  live: 'assignments_tab.stage_live',
};

// How far along an article is: its stages in order, the reached ones filled
// in, so a column of them reads as a progress chart down the class. Unlabelled,
// it's a student's later article, under the first one's labels.
export const StageTracker = ({ stages, labelled = true }) => (
  <ol className={`assignments-tab__stages${labelled ? '' : ' assignments-tab__stages--unlabelled'}`}>
    {stages.map(stage => (
      <li
        key={stage.key}
        className={stage.reached ? 'reached' : ''}
        aria-label={`${I18n.t(STAGE_LABELS[stage.key])}: ${stateLabel(stage.reached ? 'complete' : 'not_started')}`}
      >
        <span aria-hidden="true">{I18n.t(STAGE_LABELS[stage.key])}</span>
      </li>
    ))}
  </ol>
);

StageTracker.propTypes = { stages: PropTypes.array.isRequired, labelled: PropTypes.bool };

// Where to see the work before the live article: each of its pages, dimmed
// where it doesn't exist yet (still linked, since the page check can lag). The
// live article is the title's link, and its viewer once the student edits it.
export const WorkLinks = ({ article }) => {
  if (!article.pages.length) { return null; }
  return (
    <ul className="assignments-tab__work-links">
      {article.pages.map(page => (
        <li key={page.kind}>
          <a
            href={page.url} target="_blank" rel="noopener noreferrer"
            className={page.created ? '' : 'assignments-tab__missing'}
            title={page.created ? undefined : I18n.t('lti.assignment_view.article_work.not_created_yet')}
          >
            {I18n.t(STAGE_LABELS[page.kind])}
          </a>
        </li>
      ))}
    </ul>
  );
};

WorkLinks.propTypes = { article: PropTypes.object.isRequired };
