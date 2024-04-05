import React from 'react';

const CampaignRow = ({ campaign }) => {
  return (
    <tr>
      <td className="title"><a href={`/campaigns/${campaign.slug}/overview`} >{campaign.title}</a></td>
      <td><a href={`/campaigns/${campaign.slug}/students.csv`}>{I18n.t('campaign.students_small')}</a></td>
      <td><a href={`/campaigns/${campaign.slug}/students.csv?course=true`}>{I18n.t('campaign.student_course')}</a></td>
      <td>
        <a href={`/campaigns/${campaign.slug}/instructors.csv?course=true`}>{I18n.t('campaign.instructors_course')}</a>
      </td>
      <td>
        <a href={`/campaigns/${campaign.slug}/courses.csv`}>{I18n.t('campaign.course_data')}</a>
      </td>
      <td>
        <a href={`/campaigns/${campaign.slug}/articles_csv.csv`}>{I18n.t('campaign.pages_edited_small')}</a>
      </td>
      <td>
        <a href={`/campaigns/${campaign.slug}/revisions_csv.csv`}>{I18n.t('campaign.revision_data')}</a>
      </td>
    </tr>
  );
};

export default CampaignRow;
