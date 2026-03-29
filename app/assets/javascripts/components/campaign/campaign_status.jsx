import React from 'react';
import PropTypes from 'prop-types';


const CampaignStatus = ({ campaign }) => {
  const statuses = [];
  const now = new Date();
  const start = campaign.start ? new Date(campaign.start) : null;
  const end = campaign.end ? new Date(campaign.end) : null;

  if (start && start > now) {
    statuses.push({
      label: I18n.t('campaign.status.not_started'),
      className: 'is-upcoming'
    });
  } else if (end && end < now) {
    statuses.push({
      label: I18n.t('campaign.status.finished'),
      className: 'is-finished'
    });
  } else if (start || end) {
    statuses.push({
      label: I18n.t('campaign.status.ongoing'),
      className: 'is-ongoing'
    });
  }

  if (campaign.register_accounts) {
    statuses.push({
      label: I18n.t('campaign.status.registration_enabled'),
      className: 'is-registration-enabled'
    });
  }

  if (statuses.length === 0) { return null; }

  const statusElements = statuses.map((status, i) => (
    <span key={`status-${i}`} className={`campaign-status-tag ${status.className}`}>
      {status.label}
    </span>
  ));

  return (
    <div className="campaign-status-panel">
      {statusElements}
      {campaign.default_course_type && (
        <span className="campaign-type-tag">
          {I18n.t('campaign.status.default_type')}: {campaign.default_course_type}
        </span>
      )}
    </div>
  );
};

CampaignStatus.propTypes = {
  campaign: PropTypes.object.isRequired
};

export default CampaignStatus;
