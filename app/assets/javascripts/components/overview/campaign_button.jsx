import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import CourseUtils from '../../utils/course_utils.js';
import Popover from '../common/popover.jsx';
import PopoverExpandable from '../high_order/popover_expandable.jsx';
import Conditional from '../high_order/conditional.jsx';
import { removeCampaign, fetchAllCampaigns } from '../../actions/campaign_actions';
//import CampaignStore from '../../stores/campaign_store.js';

//const campaignIsNew = campaign => CampaignStore.getFiltered({ title: campaign }).length === 0;

const CampaignButton = createReactClass({
  displayName: 'CampaignButton',

  PropTypes: {
    campaigns: PropTypes.array,
    inline: PropTypes.boolean,
    open: PropTypes.func,
    is_open: PropTypes.bool
  },

  componentWillMount() {
    this.props.fetchAllCampaigns();
  },

  stop(e) {
    return e.stopPropagation();
  },

  getKey() {
    return `add_campaign`;
  },

  removeCampaign(campaignId) {
    this.props.removeCampaign(this.props.course_id, campaignId);
  },

  render() {
    const editRows = [];
    const campaignList = this.props.campaigns.map(campaign => {
      const removeButton = (
        <button className="button border plus" onClick={this.removeCampaign(campaign.title)}>-</button>
      );
      return (
        <tr key={`${campaign.id}_campaign`}>
          <td>{campaign.title}{removeButton}</td>
        </tr>
      );
    });

    const allCampaigns = ['A', 'B', 'C', 'D'];
    let buttonClass = 'button';
    buttonClass += this.props.inline ? ' border plus' : ' dark';
    const buttonText = this.props.inline ? '+' : CourseUtils.i18n('campaigns', this.props.course.string_prefix);
    const button = <button className={buttonClass} onClick={this.props.open}>{buttonText}</button>;
    return (
      <div className="pop__container" onClick={this.stop}>
        {campaignList}
        {button}
        <Popover
          is_open={this.props.is_open}
          edit_row={editRows}
          rows={allCampaigns}
        />
      </div>
    )
  }

});

// const CampaignButton = ({ campaigns }) => {
//   const editRows = [];
//   const campaignList = campaigns.map(campaign => {
//     const removeButton = (
//       <button className="button border plus" >-</button>
//     );
//     return (
//       editRows.push(
//         <tr key={`${campaign.id}_campaign`}>
//           <td>{campaign.title}{removeButton}</td>
//         </tr>
//       )
//     );
//   });
//
//
//   return (
//     <div className="pop__container" onClick={this.stop}>
//       {campaignList}
//       <Popover
//         is_open={this.props.is_open}
//         edit_row={editRows}
//         rows={users}
//       />
//       <div>{campaignList}</div>
//     </div>
//
//   );
// };
//
// CampaignButton.propTypes = {
//   campaigns: PropTypes.array
// };

const mapStateToProps = state => ({
  all_campaigns: state.campaigns.all_campaigns
});

const mapDispatchToProps = {
  removeCampaign, fetchAllCampaigns
}

export default connect(mapStateToProps, mapDispatchToProps)(
  Conditional(PopoverExpandable(CampaignButton))
);
