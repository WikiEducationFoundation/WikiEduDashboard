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
      // <div className="campaign-create">
      //   <a href={`/course_creator?campaign_slug=${props.campaign.slug}`} >
      //     <button className="button dark green" type="submit">
      //       {I18n.t('courses_generic.creator.create_short')}
      //       <i className="icon icon-plus" />
      //     </button>
      //   </a>
      // </div>
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
      <div className="campaign-create">
        <a href={`/campaigns/${props.campaign.slug}/overview}`}>
          <button className="button dark" type="submit">
            {I18n.t('campaign.requested_accounts')}
            <i className="icon icon-rt_arrow" />
          </button>
        </a>
      </div>
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
          // else {
          //   <a href={`/users/${organizer.username}`}>organizer.username</a>
          // }
        })};
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
                      <button className="button border add-organizer-button">
                        Add organizer
                      </button>
                    </form>
                  </td>
                </tr>
                props.campaign.organizers.map(organizer => {
                  <tr>
                    <td>
                      if (organizer.username == current_user){}
                    </td>
                  </tr>
                })
              </tbody>
            </table>
          </div>
        </span>

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
                <form
                  className="edit_campaign" id="edit-campaign_details" action={`/campaigns/${props.campaign.title}`} acceptCharset="UTF-8"
                  method="post"
                >
                  <div className="campaign-title form-group rails_editable-field">
                    <label>Title:</label>
                    <span className="rails_editable-content">{props.campaign.title}</span>
                  </div>
                  <div className="campaign-use-dates form-group rails_editable-field">
                    <label>
                      <input
                        type="checkbox"
                        name="use-dates"
                        id="use_dates"
                        value="1"
                      />
                      {/* 'Use start and end dates' */}
                    </label>
                  </div>
                </form>
              </div>
            </div>
          </div>
          {program_templet}
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
