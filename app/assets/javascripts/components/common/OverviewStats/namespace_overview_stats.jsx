import React from 'react';
import PropTypes from 'prop-types';
import OverviewStat from './overview_stat';

// A namespace tab counts only the students who edited pages in that namespace,
// and only edits to those pages, so its labels differ from the course
// overview's Student Editors and Total Edits.
const NamespaceOverviewStats = ({ statistics }) => {
  return (
    <div className="stat-display">
      <OverviewStat
        id="articles-created"
        className="stat-display__value"
        stat={statistics.new_count}
        statMsg={I18n.t('metrics.articles_created')}
        renderZero={false}
      />
      <OverviewStat
        id="articles-edited"
        className="stat-display__value"
        stat={statistics.edited_count}
        statMsg={I18n.t('metrics.articles_edited')}
        renderZero={false}
      />
      <OverviewStat
        id="namespace-edits"
        className="stat-display__value"
        stat={statistics.revision_count}
        statMsg={I18n.t('metrics.edits')}
        renderZero={false}
      />
      <OverviewStat
        id="active-editors"
        className="stat-display__value"
        stat={statistics.user_count}
        statMsg={I18n.t('metrics.active_editors')}
        renderZero={false}
      />
      <OverviewStat
        id="word-count"
        className="stat-display__value"
        stat={statistics.word_count}
        statMsg={I18n.t('metrics.word_count')}
        renderZero={false}
      />
      <OverviewStat
        id="references-count"
        className="stat-display__value"
        stat={statistics.reference_count}
        statMsg={I18n.t('metrics.references_count')}
        renderZero={false}
      />
      <OverviewStat
        id="view-count"
        className="stat-display__value"
        stat={statistics.view_count}
        statMsg={I18n.t('metrics.view_count_description')}
        renderZero={false}
      />
    </div>
    );
};

NamespaceOverviewStats.propTypes = {
  statistics: PropTypes.object.isRequired
};

export default NamespaceOverviewStats;
