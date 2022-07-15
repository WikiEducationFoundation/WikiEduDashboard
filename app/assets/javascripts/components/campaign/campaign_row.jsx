import React from 'react';

const CampaignRow = ({ campaign }) => {
  return (
    <tr>
      <td className="title"><a href={`/campaigns/${campaign.slug}/overview`} >{campaign.title}</a></td>
      <td><a href={`/campaigns/${campaign.slug}/students.csv`}>students</a></td>
      <td><a href={`/campaigns/${campaign.slug}/students.csv?course=true`}>students by course</a></td>
      <td>
        <a href={`/campaigns/${campaign.slug}/instructors.csv?course=true`}>instructors by course</a>
      </td>
      <td>
        <a href={`/campaigns/${campaign.slug}/courses.csv`}>course data</a>
      </td>
      <td>
        <a href={`/campaigns/${campaign.slug}/articles_csv.csv`}>pages edited</a>
      </td>
      <td>
        <a href={`/campaigns/${campaign.slug}/revisions_csv.csv`}>revision data</a>
      </td>
    </tr>
  );
};

export default CampaignRow;
