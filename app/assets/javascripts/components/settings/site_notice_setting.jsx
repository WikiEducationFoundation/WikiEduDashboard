import React from 'react';
import List from '../common/list.jsx';
import ConfigureSiteNotice from './views/configure_site_notice';
import { getSiteNotice } from '../../actions/settings_actions';
import { connect } from 'react-redux';

const SiteNoticeSetting = (props) => {
    const fetchSiteNotice = () => {
        props.getSiteNotice();
    };

    const keys = {
        current_site_notice: { label: 'Current Site Notice' }
    };

    const settingRow = (
      <tr key="default_campaign_setting">
        <td>
          {props.currentSiteNotice}
        </td>
      </tr>
    );
    fetchSiteNotice();
    return (
      <div className="site_notice_setting">
        <h2 className="mx2">Site Notice</h2>
        <ConfigureSiteNotice siteNotice={props.siteNoticeENV}/>
        <List
          elements={[settingRow]}
          keys={keys}
          table_key="current_site_notice"
        />
      </div>
    );
};

const mapStateToProps = state => ({
    siteNoticeENV: state.settings.siteNoticeENV,
    currentSiteNotice: state.settings.currentSiteNotice
});

const mapDispatchToProps = {
    getSiteNotice,
};

export default connect(mapStateToProps, mapDispatchToProps)(SiteNoticeSetting);
