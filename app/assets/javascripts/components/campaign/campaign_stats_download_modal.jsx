import React, { useState } from 'react';

const CampaignStatsDownloadModal = ({ campaign_slug }) => {
  const [show, setShow] = useState(false);

  const courseDataLink = `/campaigns/${campaign_slug}/courses.csv`;
  const articlesEditedLink = `/campaigns/${campaign_slug}/articles_csv.csv`;
  const RevisionsLink = `/campaigns/${campaign_slug}/revisions_csv.csv`;
  const editorsLink = `/campaigns/${campaign_slug}/students.csv`;
  const editorsByCourseLink = `/campaigns/${campaign_slug}/students.csv?course=true`;
  const instructorsLink = `/campaigns/${campaign_slug}/instructors.csv?course=true`;
  const wikidataLink = `/campaigns/${campaign_slug}/wikidata.csv`;

  if (!show) {
    return (
      <button onClick={() => setShow(true)} className="button">{I18n.t('courses.download_stats_data')}</button>
    );
  }

  return (
    <div className="basic-modal course-stats-download-modal">
      <button onClick={() => setShow(false)} className="pull-right article-viewer-button icon-close" />
      <h2>{I18n.t('campaign.data_download_info')}</h2>
      <hr />
      <p>
        <a href={courseDataLink} className="button right">{I18n.t('campaign.data_courses')}</a>
        {I18n.t('campaign.data_courses_info')}
      </p>
      <hr />
      <p>
        <a href={articlesEditedLink} className="button right">{I18n.t('campaign.data_articles')}</a>
        {I18n.t('campaign.data_articles_info')}
      </p>
      <hr />
      <p>
        <a href={RevisionsLink} className="button right">{I18n.t('campaign.data_revisions')}</a>
        {I18n.t('campaign.data_revisions_info')}
      </p>
      <hr />
      <p>
        <a href={editorsLink} className="button right">{I18n.t('campaign.data_editor_usernames')}</a>
        {I18n.t('campaign.data_editor_usernames_info')}
      </p>
      <hr />
      <p>
        <a href={editorsByCourseLink} className="button right">{I18n.t('campaign.data_editors_by_course')}</a>
        {I18n.t('campaign.data_editors_by_course_info')}
      </p>
      <hr />
      <p>
        <a href={instructorsLink} className="button right">{I18n.t('campaign.data_instructors')}</a>
        {I18n.t('campaign.data_instructors_info')}
      </p>
      <hr />
      <p>
        <a href={wikidataLink} className="button right">{I18n.t('campaign.data_wikidata')}</a>
        {I18n.t('campaign.data_wikidata_info')}
      </p>
    </div>
  );
};

export default CampaignStatsDownloadModal;
