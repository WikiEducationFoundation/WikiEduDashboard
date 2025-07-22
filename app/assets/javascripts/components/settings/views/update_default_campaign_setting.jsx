import React from 'react';
import DefaultCampaignForm from '../containers/default_campaign_form_container.jsx';
import Popover from '../../common/popover.jsx';
import useExpandablePopover from '../../../hooks/useExpandablePopover';

const UpdateDefaultCampaignSetting = () => {
  const getKey = () => {
    return 'update_default_campaign_button';
  };

  const { isOpen, ref, open } = useExpandablePopover(getKey);

  const form = <DefaultCampaignForm handlePopoverClose={open} />;
  return (
    <div className="pop__container" ref={ref}>
      <button className="button dark" onClick={open}>Update Default Campaign</button>
      <Popover
        is_open={isOpen}
        edit_row={form}
        right
      />
    </div>
  );
};

export default UpdateDefaultCampaignSetting;
