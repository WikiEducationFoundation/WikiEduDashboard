import React from 'react';
import CampaignStats from './campaign_stats.jsx';

const CampaignPrograms = (props) => {
  return (
    <div>
      <header className="main-page">
        <div className="container">
          <CampaignStats campaign={props.campaign} />
        </div>
      </header>
      <div className="container">
        <section id="courses">
          <div className="section-header">
            <h3>I18n.t({props.campaign.title}, course_string_prefix)</h3>
            <div className="sort-select">
              <select className="sorts" rel="courses">
                <option rel="asc" value="title">
                  {I18n.t('courses.title')}
                </option>
              </select>
            </div>
          </div>ttkkkmnnnmmlk
        </section>
      </div>
    </div>
  );
};

export default CampaignPrograms;

