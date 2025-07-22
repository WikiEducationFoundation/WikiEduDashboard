import React from 'react';
import PropTypes from 'prop-types';
import CourseUtils from '../../utils/course_utils.js';
import OverviewStat from '../common/OverviewStats/overview_stat.jsx';

const CampaignStats = ({ campaign }) => {
  const studentsInfo = [[`${campaign.trained_percent_human}%`, I18n.t('users.up_to_date_with_training')]];
  const campaignUploadsInfo = [
    [`${campaign.uploads_in_use_count_human}`, I18n.t('metrics.uploads_in_use_count', { count: campaign.uploads_in_use_count })],
    [`${campaign.upload_usage_count_human}`, I18n.t('metrics.upload_usages_count', { count: campaign.upload_usage_count })]];

  return (
    <div className="stat-display">
      <OverviewStat
        id="courses-count"
        className="stat-display__value"
        stat={campaign.courses_count}
        statMsg={CourseUtils.i18n('courses', campaign.course_string_prefix)}
        renderZero={true}
      />
      <OverviewStat
        id="students-count"
        className="stat-display__value"
        stat={campaign.user_count}
        statMsg={CourseUtils.i18n('students', campaign.course_string_prefix)}
        renderZero={true}
        info={studentsInfo}
        infoId="students-count-info"
      />
      <OverviewStat
        id="campaign-words"
        className="stat-display__value"
        stat={campaign.word_count_human}
        statMsg={I18n.t('metrics.word_count')}
        renderZero={true}
      />
      <OverviewStat
        id="campaign-references"
        className="stat-display__value"
        stat={campaign.references_count_human}
        statMsg={I18n.t('metrics.references_count')}
        renderZero={true}
        info={I18n.t('metrics.references_doc')}
        infoId="campaign-references-info"
      />
      <OverviewStat
        id="campaign-views"
        className="stat-display__value"
        stat={campaign.view_sum_human}
        statMsg={I18n.t('metrics.view_count_description')}
        renderZero={true}
        info={I18n.t('metrics.view_count_doc')}
        infoId="campaign-views-info"
      />

      <OverviewStat
        id="campaign-edited"
        className="stat-display__value"
        stat={campaign.article_count_human}
        statMsg={I18n.t('metrics.articles_edited')}
        renderZero={true}
      />
      <OverviewStat
        id="campaign-articles-count"
        className="stat-display__value"
        stat={campaign.new_article_count_human}
        statMsg={I18n.t('metrics.articles_created')}
        renderZero={true}
      />
      <OverviewStat
        id="campaign-uploads"
        className="stat-display__value"
        stat={campaign.upload_count_human}
        statMsg={I18n.t('metrics.upload_count')}
        renderZero={true}
        info={campaignUploadsInfo}
        infoId="campaign-uploads-info"
      />
    </div>
  );
};

CampaignStats.propTypes = {
  campaign: PropTypes.object.isRequired
};

export default CampaignStats;
