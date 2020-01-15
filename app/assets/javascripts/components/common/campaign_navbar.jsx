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
            {/* <ul className="campaign-nav__ul">
              <li className="nav__item" id="overview-link">
                <p><a className="active" href="/campaigns/:slug/overview">Home</a></p>
              </li>
              <li className="nav__item" id="overview-link">
                <p><a to="/campaigns/:slug/programs" >Programs</a></p>
              </li>
              <li className="nav__item" id="overview-link">
                <p><a href="/campaigns/:slug/articles">{I18n.t('courses.articles')}</a></p>
              </li>
              <li className="nav__item" id="overview-link">
                <p><a href="/campaigns/:slug/users">Editors</a></p>
              </li>
            </ul> */}
            <div className="nav__item">
              <p><NavLink className="active" to={'/campaigns/:slug/overview'}>Home</NavLink></p>
            </div>
            <div className="nav__item">
              <p><NavLink to={'/campaigns/:slug/programs'}>Programs</NavLink></p>
            </div>
            <div className="nav__item">
              <p><NavLink to={'/campaigns/:slug/articles'}>Articles</NavLink></p>
            </div>
            <div className="nav__item">
              <p><NavLink to={'/campaigns/:slug/users'}>Editors</NavLink></p>
            </div>
            <div className="nav__item">
              <p><NavLink to={'/campaigns/:slug/ores_plot'}>ORES</NavLink></p>
            </div>
            <div className="nav__item">
              <p><NavLink to={'/campaigns/:slug/alerts'}>Alerts</NavLink></p>
            </div>
            <div className="campaign-nav__search" >
              <form action="/campaigns/:slug/programs" acceptCharset="UTF-8" method="get">
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
