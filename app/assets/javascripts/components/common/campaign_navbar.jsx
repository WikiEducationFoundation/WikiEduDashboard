import React from 'react';
import PropTypes from 'prop-types';
import { NavLink } from 'react-router-dom';

const CampaignNavbar = ({ campaign }) => {
  return (
    <div className="campaign-nav__wrapper">
      <div className="campaign_navigation">
        <div className="container">
          <a className="nav__item">
            <h2 className="title">Campaign: {campaign.title}</h2>
          </a>
          <nav>
            <div className="nav__item" id="overview-link">
              <p><a href={`/campaigns/${campaign.slug}/overview`} >Home</a>
              </p>
            </div>
            <div className="nav__item">
              <p>
                <a href={`/campaigns/${campaign.slug}/programs`}>Programs</a>
              </p>
            </div>
            <div className="nav__item" id="articles-link">
              <p>
                <a href={`/campaigns/${campaign.slug}/articles`}>Articles</a>
              </p>
            </div>
            <div className="nav__item">
              <p>
                <a href={`/campaigns/${campaign.slug}/users`}>Editors</a>
              </p>
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
                  placeholder={`Search ${campaign.title}`}
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
