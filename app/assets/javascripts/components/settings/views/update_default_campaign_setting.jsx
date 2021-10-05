import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import React from 'react';
import DefaultCampaignForm from '../containers/default_campaign_form_container.jsx';
import Popover from '../../common/popover.jsx';
import PopoverExpandable from '../../high_order/popover_expandable.jsx';

const UpdateDefaultCampaignSetting = createReactClass({
  propTypes: {
    open: PropTypes.func,
    is_open: PropTypes.bool
  },

  getKey() {
    return 'update_default_campaign_button';
  },

  render() {
    const form = <DefaultCampaignForm handlePopoverClose={this.props.open} />;
    return (
      <div className="pop__container">
        <button className="button dark" onClick={this.props.open}>Update Default Campaign</button>
        <Popover
          is_open={this.props.is_open}
          edit_row={form}
          right
        />
      </div>
    );
  }
});

export default PopoverExpandable(UpdateDefaultCampaignSetting);
