import React from 'react';
import PropTypes from 'prop-types';
import CourseUtils from '../../utils/course_utils.js';
import ArticleUtils from '../../utils/article_utils.js';
import CourseStat from './course_stat';

const CourseStats = ({ course }) => {
  const isWikidata = course.home_wiki.project === 'wikidata';
  const isWikipedia = course.home_wiki.project === 'wikipedia';

  const valueClass = (stat) => {
    if (!course.newStats) { return 'stat-display__value'; }
    return course.newStats[stat] ? 'stat-display__value stat-change' : 'stat-display__value';
  };

  let editedLabel;
  let createdLabel;
  if (isWikidata) {
    createdLabel = I18n.t('metrics.articles_created_wikidata');
    editedLabel = I18n.t('metrics.articles_edited_wikidata');
  } else if (isWikipedia) {
    createdLabel = I18n.t('metrics.articles_created');
    editedLabel = I18n.t('metrics.articles_edited');
  } else {
    createdLabel = I18n.t('metrics.articles_created_generic');
    editedLabel = I18n.t('metrics.articles_edited_generic');
  }

  let pageviews;
  let infoImg;
  let trainedTooltip;
  let uploadCount;

  let articlesCreated;

  if (course.created_count !== '0') {
    articlesCreated = <CourseStat
      id="articles-created"
      className={valueClass('articles-created')}
      stat={course.created_count}
      statMsg={createdLabel}
      info={false}
    />;
  }

  let contentCount;
  if (course.home_wiki.language === 'en') {
    contentCount = <CourseStat
      id="word-count"
      className={valueClass('word-count')}
      stat={course.word_count}
      statMsg={I18n.t('metrics.word_count')}
      info={false}
    />;
  } else if (!isWikidata) {
    contentCount = <CourseStat
      id="bytes-added"
      className={valueClass('bytes-added')}
      stat={course.character_sum_human}
      statMsg={I18n.t('metrics.bytes_added')}
      info={false}
    />;
  }

  let refCount;
  if (course.references_count !== '0') {
    refCount = <CourseStat
      id="references-count"
      className={valueClass('references-count')}
      stat={course.references_count}
      statMsg={I18n.t('metrics.references_count')}
      info={I18n.t(`metrics.${ArticleUtils.projectSuffix(course.home_wiki.project, 'references_doc')}`)}
    />;
  }

  if (course.upload_usages_count === undefined) {
    return <div className="stat-display" />;
  }
  if (course.view_count !== '0') {
    pageviews = (
      <div className="stat-display__stat" id="view-count">
        <div className={valueClass('view_count')}>
          {course.view_count}
        </div>
        <small>{I18n.t(`metrics.${ArticleUtils.projectSuffix(course.home_wiki.project, 'view_count_description')}`)}</small>
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

  if (course.upload_count) {
    const infoStats = [[course.upload_usages_count, I18n.t('metrics.uploads_in_use_count', { count: course.uploads_in_use_count })],
      [course.upload_usages_count, I18n.t('metrics.upload_usages_count', { count: course.upload_usages_count })]];
    uploadCount = (
      <CourseStat
        id="upload-count"
        className={valueClass('upload_count')}
        stat={course.upload_count}
        statMsg={I18n.t('metrics.upload_count')}
        info={infoStats}
      />);
  }

  return (
    <div className="stat-display">
      {articlesCreated}
      <div className="stat-display__stat" id="articles-edited">
        <div className={valueClass('edited_count')}>{course.edited_count}</div>
        <small>{editedLabel}</small>
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
      {pageviews}
      {uploadCount}
    </div>
  );
};

CourseStats.propTypes = {
  course: PropTypes.object
};

export default CourseStats;
