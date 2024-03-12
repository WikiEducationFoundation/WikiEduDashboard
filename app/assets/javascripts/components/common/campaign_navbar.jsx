import React, { useEffect }   from 'react';
import PropTypes from 'prop-types';
import { NavLink, useLocation } from 'react-router-dom';
import CourseUtils from '../../utils/course_utils';

const CampaignNavbar = ({ campaign }) => {
  const location = useLocation();
  const pathSegments = location.pathname.split('/');
  const currentTab = pathSegments[pathSegments.length - 1];
  //useEffect needed only for links not using Navlink and can be removed once the server-rendered pages are turned into React pages that use NavLink.
  useEffect(() => {
    const links = document.querySelectorAll('.nav__item a');
    links.forEach((link) => {
      if (window.location.pathname === link.getAttribute('href')) {
      link.classList.add('active');
      } else {
      link.classList.remove('active');
      }
    });
  }, [window.location.pathname]);
  return (
    <div className="campaign-nav__wrapper">
      <div className="campaign_navigation">
        <div className="container">
          <a className="nav__item">
            <h2 className="title">{I18n.t('campaign.campaign')}: {campaign.title}</h2>
          </a>
          <nav>
            <div className={`nav__item ${currentTab === 'overview' ? 'active' : ''}`} id="overview-link">
              <p>
                <a href={`/campaigns/${campaign.slug}/overview`}>{I18n.t('courses.overview')}</a>
              </p>
            </div>
            <div className={`nav__item ${currentTab === 'programs' ? 'active' : ''}`}>
              <p>
                <a href={`/campaigns/${campaign.slug}/programs`}>{CourseUtils.i18n('courses', campaign.course_string_prefix)}</a>
              </p>
            </div>
            <div className={`nav__item ${currentTab === 'articles' ? 'active' : ''}`} id="articles-link">
              <p>
                <a href={`/campaigns/${campaign.slug}/articles`}>{I18n.t('courses.articles')}</a>
              </p>
            </div>
            <div className={`nav__item ${currentTab === 'users' ? 'active' : ''}`}>
              <p>
                <a href={`/campaigns/${campaign.slug}/users`}>{CourseUtils.i18n('students', campaign.course_string_prefix)}</a>
              </p>
            </div>
            <div className="nav__item">
              <p><NavLink to={`/campaigns/${campaign.slug}/ores_plot`}>{I18n.t('courses.ores_plot')}</NavLink></p>
            </div>
            <div className="nav__item">
              <p><NavLink to={`/campaigns/${campaign.slug}/alerts`}>{I18n.t('courses.alerts')}</NavLink></p>
            </div>
            <div className="campaign-nav__search" >
              <form action={`/campaigns/${campaign.slug}/programs`} acceptCharset="UTF-8" method="get">
                <input
                  type="text"
                  name="courses_query"
                  id="coureses_query"
                  placeholder={`${I18n.t('campaign.search')} ${campaign.title}`}
                />
                <button className="icon icon-search" type="submit" />
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
