import React, { useState } from 'react';
import TextInput from '../../common/text_input';

const FeaturedCampaignForm = ({ addFeaturedCampaign }) => {
  const [campaignSlug, setCampaignSlug] = useState();

  const handleChange = (key, value) => {
    setCampaignSlug(value);
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    addFeaturedCampaign(campaignSlug);
  };

    return (
      <tr>
        <td>
          <form onSubmit={handleSubmit}>
            <TextInput
              id="add_campaign_slug"
              editable
              onChange={handleChange}
              value={campaignSlug}
              value_key="add_campaign_slug"
              type="text"
              label="Campaign Slug"
            />
            <button className="button border" type="submit" value="Submit">{I18n.t('settings.featured_campaigns.add_button')}</button>
          </form>
        </td>
      </tr>
    );
};

export default FeaturedCampaignForm;
