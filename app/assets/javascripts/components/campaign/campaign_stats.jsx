import React from 'react';
import PropTypes from 'prop-types';
import CourseUtils from '../../utils/course_utils.js';

const CampaignStats = (props) => {
  return (
    <div className="container campaign_main">
      <section className="overview container">
        <div className="stat-display">
          <div className="stat-display__stat">
            <div className="stat-display__value">{props.campaign.courses_count}</div>
            <small>{CourseUtils.i18n('courses', props.campaign.course_string_prefix)}</small>
          </div>
          <div className="stat-display__stat tootltip-trigger">
            <div className="stat-display__value">
              {props.campaign.user_count}
              <img alt="tooltip default logo" src="/assets/images/info.svg" />
            </div>
            <small>{CourseUtils.i18n('students', props.campaign.course_string_prefix)}</small>
            <div className="tooltip dark">
              <h4>{props.campaign.trained_percent_human}%</h4>
              <p>{I18n.t('users.up_to_date_with_training')}</p>
            </div>
          </div>
          <div className="stat-display__stat">
            <div className="stat-display__value">
              {props.campaign.word_count_human}
            </div>
            <small>{I18n.t('metrics.word_count')}</small>
          </div>
          <div className="stat-display__stat tooltip-trigger">
            <div className="stat-display__value">
              {props.campaign.references_count_human}
              <img alt="tooltip default logo" src="/assets/images/info.svg" />
            </div>
            <small>{I18n.t('metrics.references_count')}</small>
            <div className="tooltip dark">
              <p>{I18n.t('metrics.references_doc')}</p>
            </div>
          </div>
          <div className="stat-display__stat">
            <div className="stat-display__value">
              {props.campaign.view_sum_human}
            </div>
            <small>{I18n.t('metrics.view_count_description')}</small>
          </div>
          <div className="stat-display__stat">
            <div className="stat-display__value">
              {props.campaign.article_count_human}
            </div>
            <small>{I18n.t('metrics.articles_edited')}</small>
          </div>
          <div className="stat-display__stat">
            <div className="stat-display__value">
              {props.campaign.new_article_count_human}
            </div>
            <small>{I18n.t('metrics.articles_created')}</small>
          </div>
          <div className="stat-display__stat tooltip-trigger">
            <div className="stat-display__value">
              {props.campaign.upload_count_human}
              <img alt="tooltip default logo" src="/assets/images/info.svg" />
            </div>
            <small>{I18n.t('metrics.upload_count')}</small>
            <div className="tooltip dark">
              <h4>{props.campaign.uploads_in_use_count_human}</h4>
              {/* <p>I18n.t('metrics.uploads_in_use_count',
                {count: props.campaign.uploads_in_use_count })
              </p> */}
              <h4>{props.campaign.upload_usage_count_human}</h4>
              {/* <p>{I18n.t['metrics.upload_usages_count', props.campaign.upload_usage_count]}</p> */}
            </div>
          </div>
        </div>
        <div className="primary">
          {/* <form className="module campaign-description rails_editable" id="edit_campaign_1" action="/campaign/miscellanea" acceptCharset="UTF-8" method="get">
            <div className="sidebar">
              if current_user && (Features.open_course_creation? || current_user&.admin?)
              <form action="course_creator_path" method="get" acceptCharset="UTF-8" className="campaign-create">
                <input name="utf8" type="hidden" id="campaign_slug[@campaign.slug]" value="" />
                <button className="button dark green">
                  {I18n.t('courses_generic.creator.create_short')}
                </button>
                <i className="icon icon-plus" />
              </form> */}
        </div>
        <div className="section-header">
          <h3>Campaign: {props.campaign.title}</h3>
          <p>{props.campaign.description}</p>
        </div>
          </form>
    </div>
      </section >
    </div >
  );
};

CampaignStats.propTypes = {
  campaign: PropTypes.object.isRequired,
  match: PropTypes.object,
};

export default CampaignStats;

