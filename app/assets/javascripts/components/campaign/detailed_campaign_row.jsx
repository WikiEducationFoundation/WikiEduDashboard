import React from 'react';

const DetailedCampaignRow = ({ campaign }) => {
  return (
    <tr>
      <td className="table-link-cell title">
        <a href={`/campaigns/${campaign.slug}`} >{campaign.title}</a>
      </td>
      <td className="table-link-cell num-courses-human">
        <a href={`/campaigns/${campaign.slug}`}>{campaign.human_course_count}</a>
      </td>
      <td className="table-link-cell articles-created-human">
        <a href={`/campaigns/${campaign.slug}`}>{campaign.human_new_article_count}</a>
      </td>
      <td className="table-link-cell articles-edited-human">
        <a href={`/campaigns/${campaign.slug}`}>{campaign.human_article_count}</a>
      </td>
      <td className="table-link-cell characters-human">
        <a href={`/campaigns/${campaign.slug}`}>{campaign.human_word_count}</a>
      </td>
      <td className="table-link-cell references-human">
        <a href={`/campaigns/${campaign.slug}`}>{campaign.human_references_count}</a>
      </td>
      <td className="table-link-cell views-human">
        <a href={`/campaigns/${campaign.slug}`}>{campaign.human_view_sum}</a>
      </td>
      <td className="table-link-cell students">
        <a href={`/campaigns/${campaign.slug}`}>{campaign.user_count}</a>
      </td>
      {!Features.wikiEd && (
        <td className="table-link-cell creation-date">
          <a href={`/campaigns/${campaign.slug}`}>{campaign.creation_date}</a>
        </td>
      )
      }
    </tr>
  );
};

export default DetailedCampaignRow;
