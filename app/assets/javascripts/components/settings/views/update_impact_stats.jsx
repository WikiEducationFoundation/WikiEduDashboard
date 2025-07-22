import React from 'react';
import ImpactStatsForm from './impact_stats_form.jsx';
import Popover from '../../common/popover.jsx';
import useExpandablePopover from '../../../hooks/useExpandablePopover';

const UpdateImpactStats = () => {
  const getKey = () => {
    return 'update_impact_stats';
  };

  const { isOpen, ref, open } = useExpandablePopover(getKey);

  const form = <ImpactStatsForm handlePopoverClose={open} />;
  return (
    <div className="pop__container" ref={ref}>
      <button className="button dark" onClick={open}>Update Impact Stats</button>
      <Popover
        is_open={isOpen}
        edit_row={form}
        right
      />
    </div>
  );
};

export default UpdateImpactStats;
