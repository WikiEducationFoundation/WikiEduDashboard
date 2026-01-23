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
