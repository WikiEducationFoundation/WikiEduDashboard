import React, { useState } from 'react';

const CampaignStatsDownloadModal = ({ match }) => {
  const [show, setShow] = useState(false);

  const campaignSlug = match.params.campaign_slug;

  const courseDataLink = `/campaigns/${campaignSlug}/courses.csv`;
  const articlesEditedLink = `/campaigns/${campaignSlug}/articles_csv.csv`;
  const RevisionsLink = `/campaigns/${campaignSlug}/revisions_csv.csv`;
  const editorsLink = `/campaigns/${campaignSlug}/students.csv`;
  const editorsByCourseLink = `/campaigns/${campaignSlug}/students.csv?course=true`;
  const instructorsLink = `/campaigns/${campaignSlug}/instructors.csv?course=true`;

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
        <a href={articlesEditedLink} className="button right">{I18n.t('campaign.data_revisions')}</a>
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
    </div>
  );
};

export default CampaignStatsDownloadModal;
