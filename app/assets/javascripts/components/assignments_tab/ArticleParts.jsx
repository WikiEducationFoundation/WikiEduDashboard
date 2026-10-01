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
// in, so a column of them reads as a progress chart down the class.
export const StageTracker = ({ stages }) => (
  <ol className="assignments-tab__stages">
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

StageTracker.propTypes = { stages: PropTypes.array.isRequired };

// Where to see the work: each page and the live article, dimmed where it
// doesn't exist yet (still linked, since the page check can lag). The live
// article's link names the article, not its stage (the student's edits in it).
export const WorkLinks = ({ article }) => {
  const links = article.pages.map(page => ({
    key: page.kind, label: I18n.t(STAGE_LABELS[page.kind]), url: page.url, exists: page.created
  }));
  links.push({
    key: 'live', label: I18n.t('assignments_tab.live_article'), url: article.url, exists: article.live
  });
  return (
    <ul className="assignments-tab__work-links">
      {links.map(link => (
        <li key={link.key}>
          <a
            href={link.url} target="_blank" rel="noopener noreferrer"
            className={link.exists ? '' : 'assignments-tab__missing'}
            title={link.exists ? undefined : I18n.t('lti.assignment_view.article_work.not_created_yet')}
          >
            {link.label}
          </a>
        </li>
      ))}
    </ul>
  );
};

WorkLinks.propTypes = { article: PropTypes.object.isRequired };
