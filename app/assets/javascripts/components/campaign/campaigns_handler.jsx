import React from 'react';
import { Route, Routes } from 'react-router-dom';
import Campaign from '../campaign/campaign.jsx';
import CampaignList from '../campaign/campaign_list.jsx';
import CampaignRow from './campaign_row';

const CampaignsHandler = () => {
  const keys = {
    title: {
      label: I18n.t('campaign.campaigns'),
      desktop_only: false,
    },
    course_count: {
      label: I18n.t(`${Features.default_course_string_prefix}.courses`),
      desktop_only: false,
      sortable: false,
    },
    new_article_count: {
      label: I18n.t('metrics.articles_created'),
      desktop_only: false,
      sortable: false,
    },
    article_count: {
      label: I18n.t('metrics.articles_edited'),
      desktop_only: false,
      sortable: false,
    },
    word_count: {
      label: I18n.t('metrics.word_count'),
      desktop_only: false,
      info_key: 'courses.word_count_doc',
      sortable: false,
    },
    references_count: {
      label: I18n.t('metrics.references_count'),
      desktop_only: false,
      info_key: 'metrics.references_doc',
      sortable: false,
    },
    view_sum: {
      label: I18n.t('metrics.view'),
      desktop_only: false,
      info_key: 'courses.view_doc',
      sortable: false,
    },
    user_count: {
      label: I18n.t('users.editors'),
      desktop_only: false,
      sortable: false,
    },
  };

  if (!Features.wikiEd) {
    keys.creation_date = {
      label: I18n.t('courses.creation_date'),
      desktop_only: false,
      sortable: false,
    };
  }

  keys.export = {
    label: I18n.t('campaign.export'),
    desktop_only: false,
    sortable: false,
  };

  return (
    <Routes>
      <Route index element={<CampaignList showSearch={true} RowElement={CampaignRow} keys={keys}/>}/>
      <Route path=":campaign_slug/*" element={<Campaign />} />
    </Routes>
  );
};

export default CampaignsHandler;
