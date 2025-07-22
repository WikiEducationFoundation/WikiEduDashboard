import React from 'react';
import Popover from '../../common/popover.jsx';
import useExpandablePopover from '../../../hooks/useExpandablePopover.js';
import { ConnectedFeaturedCampaignForm } from '../containers/featured_campaigns_contrainer.jsx';

const AddFeaturedCampaign = () => {
  const getKey = () => {
    return 'add_featured_campaign_button';
  };
  const { isOpen, ref, open } = useExpandablePopover(getKey);
  const form = <ConnectedFeaturedCampaignForm handlePopoverClose={open} />;
  return (
    <div className="pop__container" ref={ref}>
      <button className="button dark" onClick={open}>{I18n.t('settings.featured_campaigns.update_featured_campaigns_button')}</button>
      <Popover
        is_open={isOpen}
        edit_row={form}
        right
      />
    </div>
  );
};

export default AddFeaturedCampaign;
