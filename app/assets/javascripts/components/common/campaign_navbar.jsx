import React from 'react';
import PropTypes from 'prop-types';
// import CampaignOresPlot from '../campaign/campaign_ores_plot.jsx';
// import { Route, NavLink, Switch } from 'react-router-dom';
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
            <ul className="campaign-nav__ul">
              <li className="nav__item" id="overview-link">
                <p><a className="active" href="/campaigns/miscellanea/overview">Home</a></p>
              </li>
              <li className="nav__item" id="overview-link">
                <p><a to="/campaigns/miscellanea/programs" >Programs</a></p>
              </li>
              <li className="nav__item" id="overview-link">
                <p><a href="/campaigns/miscellanea/articles">{I18n.t('courses.articles')}</a></p>
              </li>
              <li className="nav__item" id="overview-link">
                <p><a href="/campaigns/miscellanea/users">Editors</a></p>
              </li>
              <li className="nav__item" id="overview-link">
                <p><a href="/campaigns/miscellanea/ores_plot">ORES</a></p>
              </li>
              <li className="nav__item" id="overview-link">
                <p><a href="/campaigns/miscellanea/alerts">Alerts</a></p>
              </li>
            </ul>

            {/* <div>
                <p><NavLink to={'/campaigns/miscellanea/alerts'} activeClassName="active">Alerts</NavLink></p>
              </div> */}
            <div className="campaign-nav__search" >
              <form action="/campaigns/miscellanea/programs" acceptCharset="UTF-8" method="get">
                <input
                  type="text"
                  name="courses_query"
                  id="coureses_query"
                  placeholder="Search"
                />
                <input
                  type="hidden"
                  name="source"
                  id="source"
                  value="nav_campaign_form"
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
