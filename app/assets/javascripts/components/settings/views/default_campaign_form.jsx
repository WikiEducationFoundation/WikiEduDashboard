import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import React from 'react';
import TextInput from '../../common/text_input';

const DefaultCampaignForm = createReactClass({
  propTypes: {
    updateDefaultCampaign: PropTypes.func,
    handlePopoverClose: PropTypes.func,
  },

  getInitialState() {
    return {};
  },

  handleChange(key, value) {
    return this.setState({ [key]: value });
  },

  handleSubmit(e) {
    e.preventDefault();
    this.props.updateDefaultCampaign(this.state.default_campaign_slug);
    this.props.handlePopoverClose(e);
  },

  render() {
    return (
      <tr>
        <td>
          <form onSubmit={this.handleSubmit}>
            <TextInput
              id="default_campaign_slug"
              editable
              onChange={this.handleChange}
              value={this.state.default_campaign_slug}
              value_key="default_campaign_slug"
              type="text"
              label="Default Campaign Slug"
            />
            <button className="button border" type="submit" value="Submit">{I18n.t('application.submit')}</button>
          </form>
        </td>
      </tr>
    );
  }
});

export default DefaultCampaignForm;
