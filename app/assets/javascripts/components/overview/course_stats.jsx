import React from 'react';
import PropTypes from 'prop-types';
import CourseUtils from '../../utils/course_utils.js';

const CourseStats = ({ course }) => {
  const valueClass = (stat) => {
    if (!course.newStats) { return 'stat-display__value'; }
    return course.newStats[stat] ? 'stat-display__value stat-change' : 'stat-display__value';
  };

  let viewData;
  let infoImg;
  let trainedTooltip;

  let contentCount;
  if (course.home_wiki.language === 'en') {
    contentCount = (
      <div className="stat-display__stat" id="word-count">
        <div className={valueClass('word_count')}>{course.word_count}</div>
        <small>{I18n.t('metrics.word_count')}</small>
      </div>
    );
  } else {
    contentCount = (
      <div className="stat-display__stat" id="bytes-added">
        <div className={valueClass('word_count')}>{course.character_sum_human}</div>
        <small>{I18n.t('metrics.bytes_added')}</small>
      </div>
    );
  }

  let refCount;
  if (course.references_count !== 0) {
    refCount = (
      <div className="stat-display__stat" id="references-added">
        <div className={valueClass('references_count')}>{course.references_count}</div>
        <small>{I18n.t('metrics.references_count')}</small>
      </div>
    );
  }

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
      <div className={valueClass('view_count')}>
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
        <div className={valueClass('created_count')}>{course.created_count}</div>
        <small>{I18n.t('metrics.articles_created')}</small>
      </div>
      <div className="stat-display__stat" id="articles-edited">
        <div className={valueClass('edited_count')}>{course.edited_count}</div>
        <small>{I18n.t('metrics.articles_edited')}</small>
      </div>
      <div className="stat-display__stat" id="total-edits">
        <div className={valueClass('edit_count')}>{course.edit_count}</div>
        <small>{I18n.t('metrics.edit_count_description')}</small>
      </div>
      <div className="stat-display__stat tooltip-trigger" id="student-editors">
        <div className={valueClass('student_count')}>
          {course.student_count}
          {infoImg}
        </div>
        <small>{CourseUtils.i18n('student_editors', course.string_prefix)}</small>
        {trainedTooltip}
      </div>
      {contentCount}
      {refCount}
      <div className="stat-display__stat" id="view-count">
        {viewData}
        <small>{I18n.t('metrics.view_count_description')}</small>
      </div>
      <div className="stat-display__stat tooltip-trigger" id="upload-count">
        <div className={valueClass('upload_count')}>
          {course.upload_count}
          <img src ="/assets/images/info.svg" alt = "tooltip default logo" />
        </div>
        <small>{I18n.t('metrics.upload_count')}</small>
        <div className="tooltip dark" id="upload-usage">
          <h4 className="stat-display__value">{course.upload_usages_count}</h4>
          <p>{I18n.t('metrics.uploads_in_use_count', { count: course.uploads_in_use_count })}</p>
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
