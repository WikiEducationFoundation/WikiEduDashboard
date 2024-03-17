import React, { useState, useEffect } from 'react';
import SiteNoticeForm from './site_notice_form.jsx';
import Popover from '../../common/popover.jsx';
import useExpandablePopover from '../../../hooks/useExpandablePopover';
import { toggleSiteNotice } from '../../../actions/settings_actions';
import { connect } from 'react-redux';

const ConfigureSiteNotice = (props) => {
  const getKey = () => {
    return 'configure_site_notice';
  };
  const { isOpen, ref, open } = useExpandablePopover(getKey);
  const [isSiteNotice, setIsSiteNotice] = useState();
  const form = <SiteNoticeForm handlePopoverClose={open}/>;

  const toggleHandler = (e) => {
    e.preventDefault();
    props.toggleSiteNotice();
    setIsSiteNotice(!isSiteNotice);
  };

  useEffect(() => {
    if (props.siteNotice === '' || props.siteNotice === null) {
      setIsSiteNotice(false);
    } else {
      setIsSiteNotice(true);
    }
  }, [props.siteNotice]);

  return (
    <div className="pop__container" ref={ref}>
      <button className="button dark" onClick={open}>Update Site Notice</button>
      <button className="button dark" disabled={isSiteNotice} onClick={toggleHandler}>Enable</button>
      <button className="button dark" disabled={!isSiteNotice} onClick={toggleHandler}>Disable</button>
      <Popover
        is_open={isOpen}
        edit_row={form}
        right
      />
    </div>
  );
};

const mapDispatchToProps = {
    toggleSiteNotice,
};

export default connect(null, mapDispatchToProps)(ConfigureSiteNotice);
