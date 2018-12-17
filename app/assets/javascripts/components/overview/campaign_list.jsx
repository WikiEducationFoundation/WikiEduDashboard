import React from 'react';
import { connect } from 'react-redux';
import _ from 'lodash';

import CourseUtils from '../../utils/course_utils.js';

const CampaignList = ({ campaigns, course }) => {
  const lastIndex = campaigns.length - 1;
  campaigns = (campaigns.length > 0
    ? _.map(campaigns, (campaign, index) => {
      let comma = '';
      const url = `/campaigns/${campaign.slug}/overview`;
      if (index !== lastIndex) { comma = ', '; }
      return <span key={campaign.slug}><a href={url}>{campaign.title}</a>{comma}</span>;
    })
    : I18n.t('courses.none'));

  return (
    <span key="campaigns_list" className="campaigns">
      <strong>{CourseUtils.i18n('campaigns', course.string_prefix)}</strong>
      <span> {campaigns}</span>
    </span>
  );
};

const mapStateToProps = state => ({
  campaigns: state.campaigns.campaigns
});

export default connect(mapStateToProps)(CampaignList);
