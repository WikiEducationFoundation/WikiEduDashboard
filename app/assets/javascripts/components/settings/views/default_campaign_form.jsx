import React, { useState } from 'react';
import TextInput from '../../common/text_input';

function DefaultCampaignForm({ updateDefaultCampaign, handlePopoverClose }) {
  const [defaultCampaign, setDedaultCampaign] = useState('');

  const handleChange = (_key, campaign) => {
    setDedaultCampaign(campaign);
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    updateDefaultCampaign(defaultCampaign);
    handlePopoverClose(e);
  };

  return (
    <tr>
      <td>
        <form onSubmit={handleSubmit}>
          <TextInput
            id="default_campaign_slug"
            editable
            onChange={handleChange}
            value={defaultCampaign}
            type="text"
            label="Default Campaign Slug"
          />
          <button className="button border" type="submit" value="Submit">{I18n.t('application.submit')}</button>
        </form>
      </td>
    </tr>
  );
}

export default DefaultCampaignForm;
