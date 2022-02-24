import React from 'react';
import { useLocation } from 'react-router-dom';
import CampaignStats from './campaign_stats';
import CampaignStatsDownloadModal from './campaign_stats_download_modal';
import CampaignNavbar from '../common/campaign_navbar';

const CampaignOverviewHandler = (props) => {
  const location = useLocation();
  let statsModal;
  if (location.pathname.match(/overview/)) {
    statsModal = (
      <div className="stats-download-modal">
        <CampaignStatsDownloadModal {...props} />;
      </div>);
  }
  let navBar;
  if (location.pathname.match(/ores_plot/) || location.pathname.match(/alerts/)) {
    navBar = (<CampaignNavbar
      campaign={props.campaign}
    />);
  }
  return (
    <div>
      {navBar}
      <CampaignStats campaign={props.campaign} />
      {statsModal}
    </div>);
};

export default CampaignOverviewHandler;
