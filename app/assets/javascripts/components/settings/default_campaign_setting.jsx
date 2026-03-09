// Component for viewing and setting the default campaign
import React from 'react';
import List from '../common/list.jsx';
import UpdateDefaultCampaignSetting from './views/update_default_campaign_setting.jsx';

const CourseCreationSettings = ({ defaultCampaign }) => {
  const keys = {
    default_campaign_slug: { label: 'Default campaign slug' }
  };

  const settingRow = (
    <tr key="default_campaign_setting">
      <td>
        {defaultCampaign}
      </td>
    </tr>
  );

  return (
    <div className="default-campaign-setting">
      <h2 className="mx2">{I18n.t('settings.common_settings_components.headings.default_campaign_setting')}</h2>
      <UpdateDefaultCampaignSetting defaultCampaign={defaultCampaign} />
      <List
        elements={[settingRow]}
        keys={keys}
        table_key="default-campaign-setting"
      />
    </div>
  );
};

export default CourseCreationSettings;
