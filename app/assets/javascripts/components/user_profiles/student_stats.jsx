import React from 'react';
import PropTypes from 'prop-types';

const StudentStats = ({ username, stats }) => {
  return (
    <div className= "user_stats">
      <h5> {I18n.t("user_profiles.student_impact", { username: username })} </h5>
      <div className= "stat-display">
        <div className= "stat-display__stat">
          <div className="stat-display__value">
            {stats.individual_courses_count}
          </div>
          <small>
            {I18n.t(`${stats.course_string_prefix}.courses_enrolled`)}
          </small>
        </div>
        <div className= "stat-display__stat">
          <div className="stat-display__value">
            {stats.individual_word_count}
          </div>
          <small>
            {I18n.t("metrics.word_count")}
          </small>
        </div>
        <div className= "stat-display__stat">
          <div className="stat-display__value">
            {stats.individual_article_views}
          </div>
          <small>
            {I18n.t("metrics.view_count_description")}
          </small>
        </div>
        <div className= "stat-display__stat">
          <div className="stat-display__value">
            {stats.individual_article_count}
          </div>
          <small>
            {I18n.t("metrics.articles_edited")}
          </small>
        </div>
        <div className= "stat-display__stat">
          <div className="stat-display__value">
            {stats.individual_articles_created}
          </div>
          <small>
            {I18n.t("metrics.articles_created")}
          </small>
        </div>
        <div className ="stat-display__stat tooltip-trigger">
          <div className="stat-display__value">
            {stats.individual_upload_count}
            <img src ="/assets/images/info.svg" alt = "tooltip default logo" />
          </div>
          <small>
            {I18n.t("metrics.upload_count")}
          </small>
          <div className="tooltip dark">
            <h4> {stats.individual_upload_usage_count} </h4>
            <p>
              {I18n.t("metrics.upload_usages_count", { count: stats.individual_upload_usage_count })}
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

StudentStats.propTypes = {
  username: PropTypes.string,
  stats: PropTypes.object
};

export default StudentStats;
