import React from 'react';
import PropTypes from 'prop-types';
import OverviewStat from './overview_stat';

const NamespaceOverviewStats = ({ data }) => {
  return (
    <div className="stat-display">
      <OverviewStat
        id="articles-created"
        className="stat-display__value"
        stat={data.new_count}
        statMsg={I18n.t('metrics.articles_created')}
        renderZero={false}
      />
      <OverviewStat
        id="articles-edited"
        className="stat-display__value"
        stat = {data.edited_count}
        statMsg={I18n.t('metrics.articles_edited')}
        renderZero={true}
      />
      <OverviewStat
        id="total-edits"
        className="stat-display__value"
        stat = {data.revision_count}
        statMsg={I18n.t('metrics.edit_count_description')}
        renderZero={true}
      />
      <OverviewStat
        id="student-editors"
        className="stat-display__value"
        stat={data.user_count}
        statMsg={'Student Editors'}
        renderZero={true}
      />
      <OverviewStat
        id="word-count"
        className="stat-display__value"
        stat={data.word_count}
        statMsg={I18n.t('metrics.word_count')}
        renderZero={true}
      />
      <OverviewStat
        id="references-count"
        className="stat-display__value"
        stat={data.references_count}
        statMsg={I18n.t('metrics.references_count')}
        renderZero={true}
      />
      <OverviewStat
        id="view-count"
        className="stat-display__value"
        stat={data.views_count}
        statMsg={I18n.t('metrics.view_count_description')}
        renderZero={true}
      />
    </div>
    );
};

NamespaceOverviewStats.propTypes = {
  data: PropTypes.object
};

export default NamespaceOverviewStats;
