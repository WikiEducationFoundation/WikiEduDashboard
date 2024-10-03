import React from 'react';
import PropTypes from 'prop-types';
import ArticleUtils from '../../utils/article_utils';

const ByStudentsStats = ({ username, stats, maxProject }) => {
  const uploads_in_use_count = ArticleUtils.projectSuffix(maxProject, 'uploads_in_use_count');

  return (
    <div className="user_stats">
      <h5>
        {I18n.t('user_profiles.instructors_student_impact', { username })}
      </h5>
      <div className="stat-display">
        <div className="stat-display__stat">
          <div className="stat-display__value">
            {stats.word_count}
          </div>
          <small>
            {I18n.t('metrics.word_count')}
          </small>
        </div>
        <div className="stat-display__stat">
          <div className="stat-display__value">
            {stats.references_count}
          </div>
          <small>
            {I18n.t('metrics.references_count')}
          </small>
        </div>
        <div className="stat-display__stat">
          <div className="stat-display__value">
            {stats.view_sum}
          </div>
          <small>
            {I18n.t(`metrics.${ArticleUtils.projectSuffix(maxProject, 'view_count_description')}`)}
          </small>
        </div>
        <div className="stat-display__stat">
          <div className="stat-display__value">
            {stats.article_count}
          </div>
          <small>
            {I18n.t(`metrics.${ArticleUtils.projectSuffix(maxProject, 'articles_edited')}`)}
          </small>
        </div>
        <div className="stat-display__stat">
          <div className="stat-display__value">
            {stats.new_article_count}
          </div>
          <small>
            {I18n.t(`metrics.${ArticleUtils.projectSuffix(maxProject, 'articles_created')}`)}
          </small>
        </div>
        <div className="stat-display__stat tooltip-trigger">
          <div className="stat-display__value">
            {stats.upload_count}
            <img src="/assets/images/info.svg" alt="tooltip default logo" />
          </div>
          <small>
            {I18n.t('metrics.upload_count')}
          </small>
          <div className="tooltip dark">
            <h4>
              {stats.uploads_in_use_count}
            </h4>
            <p>
              {I18n.t(`metrics.${uploads_in_use_count}`, { count: stats.uploads_in_use_count })}
            </p>
            <h4>{stats.upload_usage_count}</h4>
            <p>
              {I18n.t('metrics.upload_usages_count', { count: stats.upload_usage_count })}
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

ByStudentsStats.propTypes = {
  username: PropTypes.string,
  stats: PropTypes.object
};

export default ByStudentsStats;
