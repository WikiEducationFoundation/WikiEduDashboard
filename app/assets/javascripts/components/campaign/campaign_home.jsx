import React from 'react';
import PropTypes from 'prop-types';
import CampaignStats from './campaign_stats.jsx';
import TextAreaInput from '../common/text_area_input.jsx';

const CampaignHome = (props) => {
  let create_program;
  if (Features.open_course_creation? current_user :  admin) {
    create_program = (
      <div className="campaign-create
        <a href={`/course_creator?campaign_slug=${props.campaign.slug}`} >
          <button className="button dark green" type="submit">
            {I18n.t('courses_generic.creator.create_short')}
            <i className="icon icon-plus" />
          </button>
        </a>
      </div>
    );
  }
  return (
    <div className="container campaign_main">
      <section className="overview container">
        <CampaignStats campaign={props.campaign} />
        <div className="primary">
          <form className="module campaign-description rails_editable" id="edit-campaign_1" action={`/campaigns/${props.campaign.slug}`} acceptCharset="UTF-8" method="post">
            <div className="section-header">
              <h3>{I18n.t('campaign.campaign')}: {props.campaign.title}</h3>
            </div>
            <div className="module__data rails_editable-field">
              <TextAreaInput
                className="rails_editable-content"
                value={props.campaign.description}
                value_key={'description'}
                editable={false}
                markdown={true}
                autoExpand={true}
              />
            </div>
          </form>
        </div>
        <div className="sidebar">
          {create_program}

          if (current_user&&admin || user_is_organizer?) {
            <div className="campaign-create">
              <a href={`/campaigns/${props.campaign.slug}/edit?campaign_slug=${props.campaign.slug}`} >
                <button className="button dark" type="submit">
                  {I18n.t('editable.edit')}
                </button>
              </a>
            </div>
          }
          if (current_user||admin?) {
            // if (!props.campaign.register_accounts) {
            <div className="campaign-create">
              <a href={`/campaigns/${props.campaign.slug}/overview}`} >
                <button className="button dark" type="submit">
                  {I18n.t('campaign.enable_account_requests')}
                </button>
              </a>
            </div>
          }else {
            <div className="campaign-create">
              <a href={`/campaigns/${props.campaign.slug}/overview}`}>
                <button className="button dark" type="submit">
                  {I18n.t('campaign.disable_account_requests')}
                </button>
              </a>
            </div>
          }
          {/* } */}
          if (current_user&.admin? && props.campaign.requested_accounts.any?) {
            <div className="campaign-create">
              <a href={`/campaigns/${props.campaign.slug}/overview}`}>
                <button className="button dark" type="submit">
                  {I18n.t('campaign.requested_accounts')}
                  <i className="icon icon-rt_arrow" />
                </button>
              </a>
            </div>
          }
          <div className="campaign-details module rails_editable">
            <div className="section-header">
              <h3>{I18n.t('application.details')}</h3>
            </div>
            <div className="module__data extra-line-height">
              <div>
                if props.campaign.organizers.any? {
                  <span className="campaign-organizers" />
                }
                <form className="edit_campaign" id="edit-campaign_1" action={`/campaigns/${props.campaign.title}`} acceptCharset="UTF-8" method="post" >
                  <div>
                    <label>Title:</label>
                    <span className="rails_editable-content">{props.campaign.title}</span>
                  </div>
                </form>
              </div>
            </div>
          </div>
        </div>
      </section >
    </div >
  );
};

CampaignHome.propTypes = {
  campaign: PropTypes.object.isRequired,
  match: PropTypes.object,
};

export default CampaignHome;





