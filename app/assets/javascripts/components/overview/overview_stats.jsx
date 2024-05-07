import React from 'react';
import PropTypes from 'prop-types';
import CourseUtils from '../../utils/course_utils.js';
import ArticleUtils from '../../utils/article_utils.js';
import OverviewStat from '../common/OverviewStats/overview_stat';

const OverviewStats = ({ course }) => {
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


  let articlesCreated;
  if (course.created_count !== '0') {
    articlesCreated = <OverviewStat
      id="articles-created"
      className={valueClass('articles-created')}
      stat={course.created_count}
      statMsg={createdLabel}
      renderZero={false}
    />;
  }

  let contentCount;

  if (course.home_wiki.language === 'en') {
    contentCount = <OverviewStat
      id="word-count"
      className={valueClass('word-count')}
      stat={course.word_count}
      statMsg={I18n.t('metrics.word_count')}
      renderZero={true}
    />;
  } else if (!isWikidata) {
    contentCount = <OverviewStat
      id="bytes-added"
      className={valueClass('bytes-added')}
      stat={course.character_sum_human}
      statMsg={I18n.t('metrics.bytes_added')}
      renderZero={true}
    />;
  }

  if (course.upload_usages_count === undefined) {
    return <div className="stat-display" />;
  }

  let editors = (
    <OverviewStat
      id="student-editors"
      className={valueClass('student_count')}
      stat={course.student_count}
      statMsg={CourseUtils.i18n('student_editors', course.string_prefix)}
      renderZero={true}
    />
  );
  if (course.timeline_enabled) {
    const trainedInfo = [[course.trained_count, I18n.t('metrics.are_trained')]];
    editors = (
      <OverviewStat
        id="student-editors"
        className={valueClass('student_count')}
        stat={course.student_count}
        statMsg={CourseUtils.i18n('student_editors', course.string_prefix)}
        renderZero={true}
        info={trainedInfo}
        infoId="trained-info"
      />
    );
  }

  let uploadCount;
  if (course.upload_count) {
    const infoStats = [[course.uploads_in_use_count, I18n.t('metrics.uploads_in_use_count', { count: course.uploads_in_use_count })],
      [course.upload_usages_count, I18n.t('metrics.upload_usages_count', { count: course.upload_usages_count })]];
    uploadCount = (
      <OverviewStat
        id="upload-count"
        className={valueClass('upload_count')}
        stat={course.upload_count}
        statMsg={I18n.t('metrics.upload_count')}
        renderZero={true}
        info={infoStats}
        infoId="upload-info"
      />);
  }

  return (
    <div className="stat-display">
      {articlesCreated}
      <OverviewStat
        id="articles-edited"
        className={valueClass('edited_count')}
        stat={course.edited_count}
        statMsg={editedLabel}
        renderZero={true}
      />
      <OverviewStat
        id="total-edits"
        className={valueClass('edited_count')}
        stat={course.edit_count}
        statMsg={I18n.t('metrics.edit_count_description')}
        renderZero={true}
      />
      {editors}
      {contentCount}
      <OverviewStat
        id="references-count"
        className={valueClass('references-count')}
        stat={course.references_count}
        statMsg={I18n.t('metrics.references_count')}
        renderZero={false}
        info={I18n.t(`metrics.${ArticleUtils.projectSuffix(course.home_wiki.project, 'references_doc')}`)}
        infoId="references-info"
      />
      <OverviewStat
        id="view-count"
        className={valueClass('view_count')}
        stat={course.view_count}
        statMsg={I18n.t(`metrics.${ArticleUtils.projectSuffix(course.home_wiki.project, 'view_count_description')}`)}
        renderZero={false}
      />
      {uploadCount}
    </div>
  );
};

OverviewStats.propTypes = {
  course: PropTypes.object
};

export default OverviewStats;
