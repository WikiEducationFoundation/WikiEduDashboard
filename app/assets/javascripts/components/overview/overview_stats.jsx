import React from 'react';
import PropTypes from 'prop-types';
import CourseUtils from '../../utils/course_utils.js';
import ArticleUtils from '../../utils/article_utils.js';
import OverviewStat from './overview_stat';

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
    />;
  }

  let contentCount;
  if (course.home_wiki.language === 'en') {
    contentCount = <OverviewStat
      id="word-count"
      className={valueClass('word-count')}
      stat={course.word_count}
      statMsg={I18n.t('metrics.word_count')}
    />;
  } else if (!isWikidata) {
    contentCount = <OverviewStat
      id="bytes-added"
      className={valueClass('bytes-added')}
      stat={course.character_sum_human}
      statMsg={I18n.t('metrics.bytes_added')}
    />;
  }

  let refCount;
  if (course.references_count !== '0') {
    refCount = <OverviewStat
      id="references-count"
      className={valueClass('references-count')}
      stat={course.references_count}
      statMsg={I18n.t('metrics.references_count')}
      info={I18n.t(`metrics.${ArticleUtils.projectSuffix(course.home_wiki.project, 'references_doc')}`)}
      infoId="references-info"
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
        info={trainedInfo}
        infoId="trained-info"
      />
    );
  }

  let uploadCount;
  if (course.upload_count) {
    const infoStats = [[course.upload_usages_count, I18n.t('metrics.uploads_in_use_count', { count: course.uploads_in_use_count })],
      [course.upload_usages_count, I18n.t('metrics.upload_usages_count', { count: course.upload_usages_count })]];
    uploadCount = (
      <OverviewStat
        id="upload-count"
        className={valueClass('upload_count')}
        stat={course.upload_count}
        statMsg={I18n.t('metrics.upload_count')}
        info={infoStats}
        infoId="upload-info"
      />);
  }

  let wikidataStats;
  if (course.course_stats) {
    const statistics = course.course_stats.stats_hash['www.wikidata.org'];

    const itemsInfo = [[statistics['items cleared'], I18n.t('metrics.items_cleared')]];
    const claimsInfo = [[statistics['claims changed'], I18n.t('metrics.claims_changed')],
    [statistics['claims removed'], I18n.t('metrics.claims_removed')]];
    const aliasesInfo = [[statistics['aliases changed'], I18n.t('metrics.aliases_changed')],
    [statistics['aliases removed'], I18n.t('metrics.aliases_removed')]];
    const descriptionsInfo = [[statistics['descriptions changed'], I18n.t('metrics.descriptions_changed')],
    [statistics['descriptions removed'], I18n.t('metrics.descriptions_removed')]];
    const interwikiLinksInfo = [[statistics['interwiki links removed'],
    I18n.t('metrics.interwiki_links_removed')]];
    const labelsInfo = [[statistics['labels changed'], I18n.t('metrics.labels_changed')],
    [statistics['labels removed'], I18n.t('metrics.labels_removed')]];
    const mergedInfo = [[statistics['merged to'], I18n.t('metrics.merged_to')]];
    const otherUpdatesInfo = [[statistics['qualifiers added'], I18n.t('metrics.qualifiers_added')],
    [statistics['redirects created'], I18n.t('metrics.redirects_created')],
    [statistics['restorations performed'], I18n.t('metrics.restorations_performed')],
    [statistics['reverts performed'], I18n.t('metrics.reverts_performed')],
    [statistics['no data'], I18n.t('metrics.no_data')]];

    wikidataStats = (
      <>
        <OverviewStat
          id="items-created"
          className={valueClass('items-created')}
          stat={statistics['items created']}
          statMsg={I18n.t('metrics.items_created')}
          info={itemsInfo}
          infoId="items-info"
        />
        <OverviewStat
          id="claims-created"
          className={valueClass('claims-created')}
          stat={statistics['claims created']}
          statMsg={I18n.t('metrics.claims_created')}
          info={claimsInfo}
          infoId="claims-info"
        />
        <OverviewStat
          id="aliases-added"
          className={valueClass('aliases-added')}
          stat={statistics['aliases added']}
          statMsg={I18n.t('metrics.aliases_added')}
          info={aliasesInfo}
          infoId="aliases-info"
        />
        <OverviewStat
          id="descriptions-added"
          className={valueClass('descriptions-added')}
          stat={statistics['descriptions added']}
          statMsg={I18n.t('metrics.descriptions_added')}
          info={descriptionsInfo}
          infoId="descriptions-info"
        />
        <OverviewStat
          id="interwiki-links-added"
          className={valueClass('interwiki-links-added')}
          stat={statistics['interwiki links added']}
          statMsg={I18n.t('metrics.interwiki_links_added')}
          info={interwikiLinksInfo}
          infoId="interwiki-links-info"
        />
        <OverviewStat
          id="labels-added"
          className={valueClass('labels-added')}
          stat={statistics['labels added']}
          statMsg={I18n.t('metrics.labels_added')}
          info={labelsInfo}
          infoId="labels-info"
        />
        <OverviewStat
          id="merged-from"
          className={valueClass('merged-from')}
          stat={statistics['merged from']}
          statMsg={I18n.t('metrics.merged_from')}
          info={mergedInfo}
          infoId="merged-info"
        />
        <OverviewStat
          id="other-updates"
          className={valueClass('other-updates')}
          stat={statistics['other updates']}
          statMsg={I18n.t('metrics.other_updates')}
          info={otherUpdatesInfo}
          infoId="other-updates-info"
        />
      </>
    );
  }
  return (
    <div className="stat-display">
      {articlesCreated}
      <OverviewStat
        id="articles-edited"
        className={valueClass('edited_count')}
        stat={course.edited_count}
        statMsg={editedLabel}
      />
      <OverviewStat
        id="total-edits"
        className={valueClass('edited_count')}
        stat={course.edit_count}
        statMsg={I18n.t('metrics.edit_count_description')}
      />
      {editors}
      {contentCount}
      {refCount}
      {course.view_count !== '0'
        && <OverviewStat
          id="view-count"
          className={valueClass('view_count')}
          stat={course.view_count}
          statMsg={I18n.t(`metrics.${ArticleUtils.projectSuffix(course.home_wiki.project, 'view_count_description')}`)}
        />}
      {uploadCount}
      {wikidataStats}
    </div>
  );
};

OverviewStats.propTypes = {
  course: PropTypes.object
};

export default OverviewStats;
