import React, { useEffect } from 'react';
import List from '../common/list.jsx';
import ConfigureSiteNotice from './views/configure_site_notice';
import { getSiteNotice } from '../../actions/settings_actions';
import { useSelector, useDispatch } from 'react-redux';

const SiteNoticeSetting = () => {
  const dispatch = useDispatch();
  useEffect(() => {
    dispatch(getSiteNotice());
  }, []);

  const siteNotice = useSelector(state => state.settings.siteNotice);

  const keys = {
      current_site_notice: { label: 'Current Site Notice' }
  };
  const settingRow = (
    <tr key="default_campaign_setting">
      <td>
        {siteNotice.message}
      </td>
    </tr>
  );
  return (
    <div className="site_notice_setting">
      <h2 className="mx2">Site Notice</h2>
      <ConfigureSiteNotice currentSiteNotice={siteNotice}/>
      <List
        elements={[settingRow]}
        keys={keys}
        table_key="current_site_notice"
      />
    </div>
  );
};

export default SiteNoticeSetting;
