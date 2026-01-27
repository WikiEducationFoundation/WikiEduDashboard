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
    courses: {
      label: I18n.t('courses.current'),
      desktop_only: false,
    },
    articlesCreated: {
      label: I18n.t('metrics.articles_created'),
      desktop_only: false,
    },
    articlesEdit: {
      label: I18n.t('metrics.articles_edited'),
      desktop_only: false,
    },
    wordsAdded: {
      label: I18n.t('metrics.word_count'),
      desktop_only: false,
    },
    referencesAdded: {
      label: I18n.t('metrics.references_count'),
      desktop_only: false,
    },
    views: {
      label: I18n.t('metrics.view'),
      desktop_only: false,
    },
    editors: {
      label: I18n.t('users.editors'),
      desktop_only: false,
    },
    csv: {
      label: I18n.t('campaign.data_download_info'),
      desktop_only: false,
      sortable: false
    },
  };
  return (
    <Routes>
      <Route index element={<CampaignList showSearch={true} RowElement={CampaignRow} keys={keys}/>}/>
      <Route path=":campaign_slug/*" element={<Campaign />} />
    </Routes>
  );
};

export default CampaignsHandler;
