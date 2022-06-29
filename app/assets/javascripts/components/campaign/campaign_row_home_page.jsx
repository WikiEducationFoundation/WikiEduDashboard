import React from 'react';

const CampaignRowHomePage = ({ campaign }) => {
  return (
    <tr>
      <td className="table-link-cell"><a href={`/campaigns/${campaign.slug}`} >{campaign.title}</a></td>
      <td className="table-link-cell"><a href={`/campaigns/${campaign.slug}`}>{campaign.human_course_count}</a></td>
      <td className="table-link-cell"><a href={`/campaigns/${campaign.slug}`}>{campaign.human_new_article_count}</a></td>
      <td className="table-link-cell">
        <a href={`/campaigns/${campaign.slug}`}>{campaign.human_article_count}</a>
      </td>
      <td className="table-link-cell">
        <a href={`/campaigns/${campaign.slug}`}>{campaign.human_word_count}</a>
      </td>
      <td className="table-link-cell">
        <a href={`/campaigns/${campaign.slug}`}>{campaign.human_references_count}</a>
      </td>
      <td className="table-link-cell">
        <a href={`/campaigns/${campaign.slug}`}>{campaign.human_view_sum}</a>
      </td>
      <td className="table-link-cell">
        <a href={`/campaigns/${campaign.slug}`}>{campaign.user_count}</a>
      </td>
      {!Features.wikiEd && (
        <td className="table-link-cell">
          <a href={`/campaigns/${campaign.slug}`}>{campaign.creation_date}</a>
        </td>
        )
      }
    </tr>
  );
};

export default CampaignRowHomePage;
