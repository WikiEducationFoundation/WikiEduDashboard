import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import Select from 'react-select';

import { getAvailableCampaigns } from '../../selectors';
import selectStyles from '../../styles/select';

import PopoverExpandable from '../high_order/popover_expandable.jsx';
import Popover from '../common/popover.jsx';
import Conditional from '../high_order/conditional.jsx';

import { removeCampaign, fetchAllCampaigns, addCampaign } from '../../actions/campaign_actions';
import { fetchUsers } from '../../actions/user_actions';


const CampaignEditable = createReactClass({
  displayName: 'CampaignEditable',

  propTypes: {
    campaigns: PropTypes.array,
    availableCampaigns: PropTypes.array,
    fetchAllCampaigns: PropTypes.func
  },

  getInitialState() {
    return {};
  },

  componentDidMount() {
    return this.props.fetchAllCampaigns();
  },

  getKey() {
    return 'add_campaign';
  },

  handleChangeCampaign(val) {
    if (val) {
      this.setState({ selectedCampaign: val });
    } else {
      this.setState({ selectedCampaign: null });
    }
  },

  openPopover(e) {
    if (!this.props.is_open && this.refs.campaignSelect) {
      this.refs.campaignSelect.focus();
    }
    return this.props.open(e);
  },

  removeCampaign(campaignId) {
    this.props.removeCampaign(this.props.course_id, campaignId);
  },

  addCampaign() {
    // After adding the campaign, request users so that any defaults are
    // immediately propagated.
    this.props.addCampaign(this.props.course_id, this.state.selectedCampaign.value)
    .then(() => this.props.fetchUsers(this.props.course_id));

    this.setState({ selectedCampaign: null });
  },

  render() {
    // In editable mode we'll show a list of campaigns and a remove button plus a selector to add new campaigns

    const campaignList = this.props.campaigns.map((campaign) => {
      const removeButton = (
        <button className="button border plus" onClick={this.removeCampaign.bind(this, campaign.title)}>-</button>
      );
      return (
        <tr key={`${campaign.id}_campaign`}>
          <td>{campaign.title}{removeButton}</td>
        </tr>
      );
    });

    let campaignSelect;
    if (this.props.availableCampaigns.length > 0) {
      const campaignOptions = this.props.availableCampaigns.map((campaign) => {
        return { label: campaign, value: campaign };
      });
      let addCampaignButtonDisabled = true;
      if (this.state.selectedCampaign) {
        addCampaignButtonDisabled = false;
      }
      campaignSelect = (
        <tr>
          <th>
            <div className="select-with-button">
              <Select
                className="fixed-width"
                ref="campaignSelect"
                name="campaign"
                value={this.state.selectedCampaign}
                placeholder={I18n.t('courses.campaign_select')}
                onChange={this.handleChangeCampaign}
                options={campaignOptions}
                styles={selectStyles}
                isClearable
              />
              <button type="submit" className="button dark" disabled={addCampaignButtonDisabled} onClick={this.addCampaign}>
                Add
              </button>
            </div>
          </th>
        </tr>
      );
    }

    return (
      <div key="campaigns" className="pop__container campaigns open" onClick={this.stop}>
        <button className="button border plus open" onClick={this.openPopover}>+</button>
        <Popover
          is_open={this.props.is_open}
          edit_row={campaignSelect}
          rows={campaignList}
        />
      </div>
    );
  }

});

const mapStateToProps = state => ({
  availableCampaigns: getAvailableCampaigns(state),
  campaigns: state.campaigns.campaigns
});

const mapDispatchToProps = {
  removeCampaign,
  addCampaign,
  fetchAllCampaigns,
  fetchUsers
};

export default connect(mapStateToProps, mapDispatchToProps)(
  Conditional(PopoverExpandable(CampaignEditable))
);
