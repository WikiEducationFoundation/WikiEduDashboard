import React from 'react';
import PropTypes from 'prop-types';
import CampaignStats from './campaign_stats.jsx';
import TextAreaInput from '../common/text_area_input.jsx';

const CampaignHome = (props) => {
  let create_program;
  if (props.campaign.current_user) {
    create_program = (
      <form
        className="campaign-create"
        action={`/course_creator?campaign_slug=${props.campaign.slug}`}
        acceptCharset="UTF-8"
        method="get"
      >
        <button className="button dark green" type="submit">
          {I18n.t('courses_generic.creator.create_short')}
          <i className="icon icon-plus" />
        </button>
      </form>
    );
  }

  let edit;
  if (!props.campaign.editable) {
    edit = (
      <div className="campaign-create" >
        <a href={`/campaigns/${props.campaign.slug}/edit?campaign_slug=${props.campaign.slug}`} >
          <button className="button dark" type="submit">
            {I18n.t('editable.edit')}
          </button>
        </a>
      </div>
    );
  }

  let requested_accounts;
  if (props.campaign.current_user_admin && props.campaign.requested_accounts_any) {
    requested_accounts = (
      <form
        className="campaign-create"
        action={`/campaigns/${props.campaign.slug}/overview}`}
        acceptCharset="UTF-8"
        method="get"
      >
        <button className="button dark" type="submit">
          {I18n.t('campaign.requested_accounts')}
          <i className="icon icon-rt_arrow" />
        </button>
      </form>
    );
  }

  let campaign_organizers;
  if (props.campaign.organizers_any) {
    campaign_organizers = (
      <span className="campaign-organizers">
        <strong>{I18n.t('campaign.organizers')}</strong>
        {props.campaign.organizers.map((organizer, i) => {
          if (i === props.campaign.organizers.length - 1) {
            return (<a href={`/users/${organizer.username}`}>${organizer.username}</a>);
          }
          return (<a href={`/users/${organizer.username}`}>organizer.username</a>
          );
        })};
      </span>
    );
  }

  let program_templet;
  if (props.campaign.template_description_present) {
    program_templet = (
      <form
        className="module campaign-template-description rails_editable"
        id="edit_campaign_3"
        action={`/campaigns/${props.campaign.slug}`} acceptCharset="UTF-8"
        method="post"
      >
        <div className="section-header">
          <span className="tooltip-trigger">
            <h3>{I18n.t('campaign.program_template')}</h3>
            <div className="tooltip dark">
              {I18n.t('campaign.program_template_tooltip')}
            </div>
          </span>
        </div>
        <div className="module__data rails_editable-field">
          <p className="rails_editable-content">
            {props.campaign.template_description}
          </p>
        </div>
      </form>
    );
  }

  let campaign_start_end;
  let use_dates;
  if (use_dates === props.campaign.start || props.campaign.end) {
    campaign_start_end = (
      <label>
        <input
          type="checkbox"
          value="1"
          name="use_dates"
        />{I18n.t('campaign.use_start_end_dates')}
      </label>
    );
  }

  return (
    <div className="container campaign_main">
      <section className="overview container">
        <CampaignStats campaign={props.campaign} />
        <div className="primary">
          <form className="module campaign-description rails_editable" id="edit-campaign_3" action={`/campaigns/${props.campaign.slug}`} acceptCharset="UTF-8" method="post">
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
          {edit}
          {requested_accounts}
          <div className="campaign-details module rails_editable">
            <div className="section-header">
              <h3>{I18n.t('application.details')}</h3>
            </div>
            <div className="module__data extra-line-height">
              <div>
                {campaign_organizers}
                <span className="pop__container">
                  <button className="button border plus">+</button>
                  <div className="pop">
                    <table>
                      <tbody>
                        <tr className="edit">
                          <td>
                            <form
                              action={`add_organizer_campaign_path${props.campaign.slug}`} acceptCharset="UTF-8"
                              method="put"
                            >
                              <textarea
                                type="text"
                                id="username"
                                name="username"
                                required
                                placeholder={I18n.t('users.username_placeholder')}
                              />
                            </form>
                          </td>
                        </tr>
                      </tbody>
                    </table>
                  </div>
                </span>
                <form
                  id="edit_campaign_details"
                  action={`/campaigns/${props.campaign.slug}`}
                >
                  <div className="campaign-use-dates form-group rails_editable-field">
                    {campaign_start_end}
                  </div>
                </form>
              </div>
            </div>
          </div>
          {program_templet}
        </div >
      </section >
    </div >
  );
};

CampaignHome.propTypes = {
  campaign: PropTypes.object.isRequired,
  match: PropTypes.object,
};

export default CampaignHome;
