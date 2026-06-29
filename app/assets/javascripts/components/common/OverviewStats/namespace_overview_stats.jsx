import React from 'react';
import PropTypes from 'prop-types';
import OverviewStat from './overview_stat';
import CourseUtils from '../../../utils/course_utils';

const NamespaceOverviewStats = ({ course, statistics }) => {
  const student_editors_stat_msg = CourseUtils.i18n('student_editors', course.string_prefix);
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
        id="total-edits"
        className="stat-display__value"
        stat={statistics.revision_count}
        statMsg={I18n.t('metrics.edit_count_description')}
        renderZero={false}
      />
      <OverviewStat
        id="student-editors"
        className="stat-display__value"
        stat={statistics.user_count}
        statMsg={student_editors_stat_msg}
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
        stat={statistics.references_count}
        statMsg={I18n.t('metrics.references_count')}
        renderZero={false}
      />
      <OverviewStat
        id="view-count"
        className="stat-display__value"
        stat={statistics.views_count}
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
