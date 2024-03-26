import React, { useState, useEffect } from 'react';
import SiteNoticeForm from './site_notice_form.jsx';
import Popover from '../../common/popover.jsx';
import useExpandablePopover from '../../../hooks/useExpandablePopover';
import { updateSiteNotice } from '../../../actions/settings_actions';
import { useDispatch } from 'react-redux';

const ConfigureSiteNotice = (props) => {
  const [isSiteNotice, setIsSiteNotice] = useState();
  const dispatch = useDispatch();

  const getKey = () => {
    return 'configure_site_notice';
  };

  const { isOpen, ref, open } = useExpandablePopover(getKey);
  const form = <SiteNoticeForm handlePopoverClose={open} updateSiteNotice={updateSiteNotice} currentStatus={props.currentSiteNotice.status} />;

  const toggleHandler = (e) => {
    e.preventDefault();
    dispatch(updateSiteNotice({ status: !isSiteNotice }));
    setIsSiteNotice(!isSiteNotice);
  };

  useEffect(() => {
    setIsSiteNotice(props.currentSiteNotice.status);
  }, [props.currentSiteNotice]);


  return (
    <div className="pop__container" ref={ref}>
      <button className="button dark" onClick={open}>Update Site Notice</button>
      <button
        className="button dark"
        disabled={isSiteNotice || props.currentSiteNotice.message === null}
        onClick={toggleHandler}
      >
        Enable
      </button>
      <button className="button dark" disabled={!isSiteNotice} onClick={toggleHandler}>Disable</button>
      <Popover
        is_open={isOpen}
        edit_row={form}
        right
      />
    </div>
  );
};

export default ConfigureSiteNotice;

