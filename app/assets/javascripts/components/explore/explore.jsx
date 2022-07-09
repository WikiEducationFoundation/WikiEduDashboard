import I18n from 'i18n-js';
import React from 'react';
import { useSelector } from 'react-redux';
import { getCurrentUser } from '../../selectors';
import DetailedCampaignList from '../campaign/detailed_campaign_list';
import ActiveCourseList from '../course/active_course_list';
import SearchableCourseList from '../course/searchable_course_list';

const Explore = () => {
  const user = getCurrentUser(useSelector(state => state));
  const showCreateButton = user.admin || Features.open_course_creation;
  return (
    <>
      <SearchableCourseList/>
      <div id="campaigns_list">
        <DetailedCampaignList headerText={I18n.t('campaign.newest_campaigns')} newest/>
        <div className="campaigns-actions" >
          {showCreateButton && <a className="button dark" href="campaigns/new?create=true">{I18n.t('campaign.create_campaign')}</a>}
          <a href="/campaigns" className="button">
            {I18n.t('campaign.all_campaigns')} <span className="icon icon-rt_arrow" />
          </a>
        </div>
      </div>
      {Features.wikiEd
      && (
        <div id="active_courses">

          <ActiveCourseList />
          <div className="campaigns-actions">
            {showCreateButton && <a className="button dark" href="/course_creator">{I18n.t(`${Features.course_string_prefix}.creator.create_new`)}</a>}
            <a href="/campaigns" className="button">
              {I18n.t(`${Features.course_string_prefix}.all_courses`)} <span className="icon icon-rt_arrow" />
            </a>
          </div>
        </div>
      )}

    </>
  );
};

export default Explore;
