import React, { useState } from 'react';
import { toast } from 'react-toastify';

const CampaignStatsDownloadModal = ({ campaign_slug }) => {
  const handleStatsDownload = (e) => {
    e.preventDefault();
    const url = e.currentTarget.href;
    fetch(url, { method: 'GET' }).then((response) => {
      const contentType = response.headers.get('content-type');
      if (contentType && contentType.includes('text/plain')) {
        response.text().then((text) => {
          toast(text, { position: 'bottom-center', type: 'info', autoClose: 3000, icon: false });
        });
      } else {
        window.location.href = url;
      }
    });
    };

  const [show, setShow] = useState(false);

  const courseDataLink = `/campaigns/${campaign_slug}/courses.csv`;
  const articlesEditedLink = `/campaigns/${campaign_slug}/articles_csv.csv`;
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
        <a onClick={handleStatsDownload} href={courseDataLink} className="button right">{I18n.t('campaign.data_courses')}</a>
        {I18n.t('campaign.data_courses_info')}
      </p>
      <hr />
      <p>
        <a onClick={handleStatsDownload} href={articlesEditedLink} className="button right">{I18n.t('campaign.data_articles')}</a>
        {I18n.t('campaign.data_articles_info')}
      </p>
      <hr />
      <p>
        <a onClick={handleStatsDownload} href={editorsLink} className="button right">{I18n.t('campaign.data_editor_usernames')}</a>
        {I18n.t('campaign.data_editor_usernames_info')}
      </p>
      <hr />
      <p>
        <a onClick={handleStatsDownload} href={editorsByCourseLink} className="button right">{I18n.t('campaign.data_editors_by_course')}</a>
        {I18n.t('campaign.data_editors_by_course_info')}
      </p>
      <hr />
      <p>
        <a onClick={handleStatsDownload} href={instructorsLink} className="button right">{I18n.t('campaign.data_instructors')}</a>
        {I18n.t('campaign.data_instructors_info')}
      </p>
      <hr />
      <p>
        <a onClick={handleStatsDownload} href={wikidataLink} className="button right">{I18n.t('campaign.data_wikidata')}</a>
        {I18n.t('campaign.data_wikidata_info')}
      </p>
    </div>
  );
};

export default CampaignStatsDownloadModal;
