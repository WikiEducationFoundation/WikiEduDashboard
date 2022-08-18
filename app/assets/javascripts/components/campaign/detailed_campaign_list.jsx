import React from 'react';
import CampaignList from './campaign_list';
import DetailedCampaignRow from './detailed_campaign_row';

const DetailedCampaignList = ({ newest, headerText, userOnly }) => {
  const keys = {
    title: {
      label: I18n.t('campaign.campaigns'),
      desktop_only: false,
    },
    course_count: {
      label: I18n.t(`${Features.default_course_string_prefix}.courses`),
      desktop_only: false,
    },
    new_article_count: {
      label: I18n.t('metrics.articles_created'),
      desktop_only: false
    },
    article_count: {
      label: I18n.t('metrics.articles_edited'),
      desktop_only: false
    },
    word_count: {
      label: I18n.t('metrics.word_count'),
      desktop_only: false,
      info_key: 'courses.view_doc'
    },
    references_count: {
      label: I18n.t('metrics.references_count'),
      desktop_only: false,
      info_key: 'metrics.references_doc'
    },
    view_sum: {
      label: I18n.t('metrics.view'),
      desktop_only: false,
      info_key: 'courses.view_doc'
    },
    user_count: {
      label: I18n.t('users.editors'),
      desktop_only: false
    },
  };
  if (!Features.wikiEd) {
    keys.creation_date = {
      label: I18n.t('courses.creation_date'),
      desktop_only: false
    };
  }
  return (
    <CampaignList RowElement={DetailedCampaignRow} keys={keys} newest={newest} headerText={headerText} userOnly={userOnly} showStatistics/>
  );
};

export default DetailedCampaignList;
