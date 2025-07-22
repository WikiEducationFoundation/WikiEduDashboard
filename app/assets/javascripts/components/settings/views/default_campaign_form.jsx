import React, { useState } from 'react';
import PropTypes from 'prop-types';
import TextInput from '../../common/text_input';

const DefaultCampaignForm = (props) => {
  const [default_campaign_slug, setDefault_campaign_slug] = useState(null);

  const handleChange = (key, value) => {
    setDefault_campaign_slug(value);
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    props.updateDefaultCampaign(default_campaign_slug);
    props.handlePopoverClose(e);
  };
  return (
    <tr>
      <td>
        <form onSubmit={handleSubmit}>
          <TextInput
            id="default_campaign_slug"
            editable
            onChange={handleChange}
            value={default_campaign_slug}
            value_key="default_campaign_slug"
            type="text"
            label="Default Campaign Slug"
          />
          <button className="button border" type="submit" value="Submit">{I18n.t('application.submit')}</button>
        </form>
      </td>
    </tr>
  );
};

DefaultCampaignForm.propTypes = {
  updateDefaultCampaign: PropTypes.func,
  handlePopoverClose: PropTypes.func,
};

export default DefaultCampaignForm;
