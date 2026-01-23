import React, { useState } from 'react';
import { toast } from 'react-toastify';

const CampaignRow = ({ campaign }) => {
  const handleCsvDownload = (e) => {
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

  const [showDownloadModal, setShowDownloadModal] = useState(false);
  return (
    <>
      <tr>
        <td className="title"><a href={`/campaigns/${campaign.slug}/overview`} >{campaign.title}</a></td>
        <td className="courses">
          {campaign.courses}
        </td>
        <td className="csv">
          <button onClick={() => setShowDownloadModal(true)} className="button">{I18n.t('campaign.download_csvs_data')}</button>
        </td>
      </tr>

      {showDownloadModal && (
        <CampaignCsvsDownloadModal
          campaign={campaign}
          onClose={() => setShowDownloadModal(false)}
          handleCsvDownload={handleCsvDownload}
        />
      )}
    </>
  );
};


const CampaignCsvsDownloadModal = ({ onClose, campaign, handleCsvDownload }) => {
  return (
    <div className="basic-modal course-stats-download-modal">
      <button onClick={onClose} className="pull-right article-viewer-button icon-close" />
      <h2>{I18n.t('campaign.data_download_info')}</h2>
      <hr />
      <p>
        <a onClick={handleCsvDownload} href={`/campaigns/${campaign.slug}/students.csv`} className="button right">{I18n.t('campaign.students_small')}</a>
      </p>
      <hr />
      <p>
        <a onClick={handleCsvDownload} href={`/campaigns/${campaign.slug}/students.csv?course=true`} className="button right">{I18n.t('campaign.student_course')}</a>
      </p>
      <hr />
      <p>
        <a onClick={handleCsvDownload} href={`/campaigns/${campaign.slug}/instructors.csv?course=true`} className="button right">{I18n.t('campaign.instructors_course')}</a>
      </p>
      <hr />
      <p>
        <a onClick={handleCsvDownload} href={`/campaigns/${campaign.slug}/courses.csv`} className="button right">{I18n.t('campaign.course_data')}</a>
      </p>
      <hr />
      <p>
        <a onClick={handleCsvDownload} href={`/campaigns/${campaign.slug}/articles_csv.csv`} className="button right">{I18n.t('campaign.pages_edited_small')}</a>
      </p>
      <hr />
    </div>
  );
};

export default CampaignRow;
