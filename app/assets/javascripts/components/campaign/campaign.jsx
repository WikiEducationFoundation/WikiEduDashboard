import { Route, Routes, useParams } from 'react-router-dom';
import React, { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { getCampaign } from '../../actions/campaign_view_actions';
import CampaignAlerts from '../alerts/campaign_alerts.jsx';
import CampaignOresPlot from './campaign_ores_plot.jsx';
import CampaignNavbar from '../common/campaign_navbar';
import CampaignStats from './campaign_stats';
import WikidataOverviewStats from '../common/wikidata_overview_stats';
import CampaignStatsDownloadModal from './campaign_stats_download_modal';

export const Campaign = () => {
  const dispatch = useDispatch();
  const campaign = useSelector(state => state.campaign);

  const { campaign_slug } = useParams();

  useEffect(() => { dispatch(getCampaign(campaign_slug)); }, []);

  if (campaign.loading) {
    return <div />;
  }

  let campaignHandler;
  if (window.location.href.match(/overview/)) {
    campaignHandler = (
      <div className="high-modal">
        <CampaignStatsDownloadModal campaign_slug={campaign_slug} />
      </div>
    );
  }

  return (
    <div>
      <CampaignNavbar
        campaign={campaign}
      />
      <div className="container campaign_main">
        <section className="overview container">
          <CampaignStats campaign={campaign} />
          {campaign.course_stats && <WikidataOverviewStats
            statistics={campaign.course_stats['www.wikidata.org']}
          />}
        </section>
        {campaignHandler}
        <Routes>
          <Route path="ores_plot" element={<CampaignOresPlot />} />
          <Route path="alerts" element={<CampaignAlerts />} />
        </Routes>
      </div>
    </div >
  );
};

export default (Campaign);
