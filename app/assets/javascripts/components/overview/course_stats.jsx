import React from 'react';
import PropTypes from 'prop-types';
import CourseUtils from '../../utils/course_utils.js';

const CourseStats = ({ course }) => {
  let viewData;
  let infoImg;
  let trainedTooltip;
  if (course.upload_usages_count === undefined) {
    return <div className="stat-display" />;
  }
  if (course.view_count === '0' && course.edited_count !== '0') {
    viewData = (
      <div className="stat-display__data">
        {I18n.t('metrics.view_data_unavailable')}
      </div>
    );
  } else {
    viewData = (
      <div className="stat-display__value">
        {course.view_count}
      </div>
    );
  }
  if (course.timeline_enabled) {
    infoImg = (
      <img src ="/assets/images/info.svg" alt = "tooltip default logo" />
    );
    trainedTooltip = (
      <div className="tooltip dark" id="trained-count">
        <h4 className="stat-display__value">{course.trained_count}</h4>
        <p>{I18n.t('metrics.are_trained')}</p>
      </div>
    );
  }

  return (
    <div className="stat-display">
      <div className="stat-display__stat" id="articles-created">
        <div className="stat-display__value">{course.created_count}</div>
        <small>{I18n.t('metrics.articles_created')}</small>
      </div>
      <div className="stat-display__stat" id="articles-edited">
        <div className="stat-display__value">{course.edited_count}</div>
        <small>{I18n.t('metrics.articles_edited')}</small>
      </div>
      <div className="stat-display__stat" id="total-edits">
        <div className="stat-display__value">{course.edit_count}</div>
        <small>{I18n.t('metrics.edit_count_description')}</small>
      </div>
      <div className="stat-display__stat tooltip-trigger" id="student-editors">
        <div className="stat-display__value">
          {course.student_count}
          {infoImg}
        </div>
        <small>{CourseUtils.i18n('student_editors', course.string_prefix)}</small>
        {trainedTooltip}
      </div>
      <div className="stat-display__stat" id="word-count">
        <div className="stat-display__value">{course.word_count}</div>
        <small>{I18n.t('metrics.word_count')}</small>
      </div>
      <div className="stat-display__stat" id="view-count">
        {viewData}
        <small>{I18n.t('metrics.view_count_description')}</small>
      </div>
      <div className="stat-display__stat tooltip-trigger" id="upload-count">
        <div className="stat-display__value">
          {course.upload_count}
          <img src ="/assets/images/info.svg" alt = "tooltip default logo" />
        </div>
        <small>{I18n.t('metrics.upload_count')}</small>
        <div className="tooltip dark" id="upload-usage">
          <h4 className="stat-display__value">{course.upload_usages_count}</h4>
          <p>{I18n.t('metrics.uploads_in_use_count', { count: course.upload_usages_count })}</p>
          <h4 className="stat-display__value">{course.upload_usages_count}</h4>
          <p>{I18n.t('metrics.upload_usages_count', { count: course.upload_usages_count })}</p>
        </div>
      </div>
    </div>
  );
};

CourseStats.propTypes = {
  course: PropTypes.object
};

export default CourseStats;
