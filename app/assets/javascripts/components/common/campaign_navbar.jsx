import React from 'react';
import { NavLink } from 'react-router-dom';
// import TextInput from './text_input.jsx';

const CampaignNavbar = ({ campaign, campaignLink }) => {
  const homeLink = `${campaign.slug}/overview`;
  const programsLink = `${campaignLink}/programs`;
  const articlesLink = `${campaign.slug}/articles`;
  const editorsLink = `${campaignLink}/users`;
  const oresLink = `${campaignLink}/ores/plot`;
  const alertsLink = `${campaignLink}/alerts`;

  // const searchDefaultCampaign = (
  //   <TextInput
  //     id={this.props.campaign.id}
  //     value="Search Default Campaign"
  //   />
  // );
  return (
    <div className="container">
      <h2 className="title">Campaign:{campaign.title}</h2>
      <nav>
        <div className="nav__item" id="overview-link">
          <p><NavLink to={homeLink} activeClassName="active">{I18n.t('courses.overview')}</NavLink>
          </p>
        </div>
        <div className="nav__item" id="programs-link">
          <p><NavLink to={programsLink} activeClassName="active">{I18n.t('course_string_prefix').courses}</NavLink></p>
        </div>
        <div className="nav__item" id="srticles-link">
          <p><NavLink to={articlesLink} activeClassName="active">{I18n.t('courses.articles')}</NavLink></p>
        </div>
        <div className="nav__item" id="students-link">
          <p><NavLink to={editorsLink} activeClassName="active">{I18n.t('campaign.course_string_prefix').students}</NavLink></p>
        </div>
        <div className="nav__item" id="ores-link">
          <p><NavLink to={oresLink} activeClassName="active">{I18n.t('courses.ores_plot')}</NavLink></p>
        </div>
        <div className="nav__item" id="ores-link">
          <p><NavLink to={alertsLink} activeClassName="active">{I18n.t('courses.alerts')}</NavLink></p>
        </div>
      </nav>
      {/* {searchDefaultCampaign} */}
    </div>
  );
};

export default CampaignNavbar;
