import React from 'react';
import PropTypes from 'prop-types';
// import CampaignOresPlot from '../campaign/campaign_ores_plot.jsx';
import { NavLink } from 'react-router-dom';
// import Alert from '../alerts/alert.jsx';

const CampaignNavbar = ({ campaign }) => {
  return (
    <div className="campaign-nav__wrapper">
      <div className="campaign_navigation">
        <div className="container">
          <a className="nav__item">
            <h2 className="title">Campaign: {campaign.title}</h2>
          </a>
          <nav>
            <div className="nav__item">
              <p><NavLink className="active" to={`/campaigns/${campaign.slug}/overview`}>Home</NavLink></p>
            </div>
            <div className="nav__item">
              <p><NavLink to={`/campaigns/${campaign.slug}/programs`}>Programs</NavLink></p>
            </div>
            <div className="nav__item">
              <p><NavLink to={`/campaigns/${campaign.slug}/articles`}>Articles</NavLink></p>
            </div>
            <div className="nav__item">
              <p><NavLink to={`/campaigns/${campaign.slug}/users`}>Editors</NavLink></p>
            </div>
            <div className="nav__item">
              <p><NavLink to={`/campaigns/${campaign.slug}/ores_plot`}>ORES</NavLink></p>
            </div>
            <div className="nav__item">
              <p><NavLink to={`/campaigns/${campaign.slug}/alerts`}>Alerts</NavLink></p>
            </div>
            <div className="campaign-nav__search" >
              <form action={`/campaigns/${campaign.slug}/programs`} acceptCharset="UTF-8" method="get">
                <input
                  type="text"
                  name="courses_query"
                  id="coureses_query"
                  placeholder="Search"
                />
                <button type="submit">
                  <i className="icon icon-search" />
                </button>
              </form>
            </div>
          </nav>
        </div>
      </div>
    </div>
  );
};

CampaignNavbar.propTypes = {
  campaign: PropTypes.object,
};

export default CampaignNavbar;
