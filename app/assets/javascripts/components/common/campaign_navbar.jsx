import React, { useState, useEffect} from 'react';
import PropTypes from 'prop-types';
import { NavLink } from 'react-router-dom';
import CourseUtils from '../../utils/course_utils';

const CampaignNavbar = ({ campaign }) => {
  const [activeTab, setActiveTab] = useState(localStorage.getItem('activeTab') || 'overview');
    const handleTabClick = (tabName) => {
        setActiveTab(tabName);
        localStorage.setItem('activeTab', tabName);
    };

    useEffect(() => {
        const handleStorageChange = () => {
            const storedTab = localStorage.getItem('activeTab');
            if (storedTab && storedTab !== activeTab) {
                setActiveTab(storedTab);
            }
        };
        window.addEventListener('storage', handleStorageChange);

        return () => {
            window.removeEventListener('storage', handleStorageChange);
        };
    }, [activeTab]);
  return (
    <div className="campaign-nav__wrapper">
      <div className="campaign_navigation">
        <div className="container">
          <a className="nav__item">
            <h2 className="title">{I18n.t('campaign.campaign')}: {campaign.title}</h2>
          </a>
          <nav>
          <div className={`nav__item ${activeTab === 'overview' ? 'active' : ''}`} id="overview-link">
              <p><a href={`/campaigns/${campaign.slug}/overview`} onClick={() => handleTabClick('overview')}>{I18n.t('courses.overview')}</a></p>
            </div>
            <div className={`nav__item ${activeTab === 'programs' ? 'active' : ''}`}>
              <p><a href={`/campaigns/${campaign.slug}/programs`} onClick={() => handleTabClick('programs')}>{CourseUtils.i18n('courses', campaign.course_string_prefix)}</a></p>
            </div>
            <div className={`nav__item ${activeTab === 'articles' ? 'active' : ''}`} id="articles-link">
              <p><a href={`/campaigns/${campaign.slug}/articles`} onClick={() => handleTabClick('articles')}>{I18n.t('courses.articles')}</a></p>
            </div>
            <div className={`nav__item ${activeTab === 'users' ? 'active' : ''}`}>
              <p><a href={`/campaigns/${campaign.slug}/users`} onClick={() => handleTabClick('users')}>{CourseUtils.i18n('students', campaign.course_string_prefix)}</a></p>
            </div>
            <div className={`nav__item ${activeTab === 'ores_plot' ? 'active' : ''}`}>
              <p><NavLink to={`/campaigns/${campaign.slug}/ores_plot`} onClick={() => handleTabClick('ores_plot')}>{I18n.t('courses.ores_plot')}</NavLink></p>
            </div>
            <div className={`nav__item ${activeTab === 'alerts' ? 'active' : ''}`}>
              <p><NavLink to={`/campaigns/${campaign.slug}/alerts`} onClick={() => handleTabClick('alerts')}>{I18n.t('courses.alerts')}</NavLink></p>
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
