import React from 'react';
import { toast } from 'react-toastify';

const CampaignRow = ({ campaign }) => {
  const handleStatsDownload = (e) => {
    e.preventDefault();
    const url = e.currentTarget.href;
    fetch(url, { method: 'GET' }).then((response) => {
      // If the content type is text/plain, it means the file is being generated
      // and the server returned a text message.
      const contentType = response.headers.get('content-type');
      if (contentType && contentType.includes('text/plain')) {
        response.text().then((text) => {
          toast(text, { position: 'bottom-center', type: 'info', autoClose: 3000, icon: false });
        });
      } else {
        // Otherwise, proceed with the download
        window.location.href = url;
      }
    });
  };

  return (
    <tr>
      <td className="title"><a href={`/campaigns/${campaign.slug}/overview`} >{campaign.title}</a></td>
      <td className="csv">
        <a onClick={handleStatsDownload} href={`/campaigns/${campaign.slug}/students.csv`}>{I18n.t('campaign.students_small')}</a>
        {' | '}
        <a onClick={handleStatsDownload} href={`/campaigns/${campaign.slug}/students.csv?course=true`}>{I18n.t('campaign.student_course')}</a>
        {' | '}
        <a onClick={handleStatsDownload} href={`/campaigns/${campaign.slug}/instructors.csv?course=true`}>{I18n.t('campaign.instructors_course')}</a>
        {' | '}
        <a onClick={handleStatsDownload} href={`/campaigns/${campaign.slug}/courses.csv`}>{I18n.t('campaign.course_data')}</a>
        {' | '}
        <a onClick={handleStatsDownload} href={`/campaigns/${campaign.slug}/articles_csv.csv`}>{I18n.t('campaign.pages_edited_small')}</a>
      </td>
    </tr>
  );
};

export default CampaignRow;
