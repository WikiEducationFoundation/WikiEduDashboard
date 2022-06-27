import React from 'react';
import { Route, Routes } from 'react-router-dom';
import Campaign from '../campaign/campaign.jsx';
import CampaignList from '../campaign/campaign_list.jsx';

const CampaignsHandler = () => {
  return (
    <Routes>
      <Route index element={<CampaignList/>}/>
      <Route path=":campaign_slug/*" element={<Campaign />} />
    </Routes>
  );
};

export default CampaignsHandler;
