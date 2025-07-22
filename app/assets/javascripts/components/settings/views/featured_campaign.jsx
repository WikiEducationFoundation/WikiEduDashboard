import React from 'react';
import PropTypes from 'prop-types';

const FeaturedCampaign = ({ slug, title, removeFeaturedCampaign }) => {
  const handleClick = () => {
    removeFeaturedCampaign(slug);
  };
  return (
    <tr className="campaign">
      <td className="campaign_title">
        <p>{title}</p>
      </td>
      <td className="campaign_slug">
        <p>{slug}</p>
      </td>
      <td className="campaign_remove">
        <p>
          <button
            className="button danger"
            onClick={handleClick}
          >
            {I18n.t('settings.featured_campaigns.remove_button')}
          </button>
        </p>
      </td>
    </tr>
  );
};

FeaturedCampaign.propTypes = {
  slug: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired,
  removeFeaturedCampaign: PropTypes.func.isRequired
};

export default FeaturedCampaign;
