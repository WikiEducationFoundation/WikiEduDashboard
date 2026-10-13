import React from 'react';
import PropTypes from 'prop-types';
import { useDispatch } from 'react-redux';
import { addDownload, updateDownload } from '../../actions/download_actions';
import { addNotification } from '../../actions/notification_actions';
import { profileCsv } from '../../utils/user_profile_export';

const ProfileDownloadButtons = ({ username, section, data }) => {
  const dispatch = useDispatch();

  const download = (format) => {
    const id = `user-${username}-${section}-${format}`;
    const label = `${username} — ${I18n.t(`downloads.${format}`)}`;
    dispatch(addDownload({ id, label, status: 'pending', createdAt: Date.now() }));
    try {
      const content = format === 'csv' ? profileCsv(data) : JSON.stringify(data, null, 2);
      const mime = format === 'csv' ? 'text/csv' : 'application/json';
      // Data URLs keep the download available in the existing persisted download list.
      const downloadUrl = `data:${mime};charset=utf-8,${encodeURIComponent(content)}`;
      const safeUsername = username.replace(/[^\p{L}\p{N}_-]/gu, '_');
      const filename = `${safeUsername}_${section}.${format}`;
      dispatch(updateDownload(id, { status: 'ready', downloadUrl, filename }));
      dispatch(addNotification({
        message: I18n.t('downloads.available_in_bell'),
        type: 'success',
        closable: true
      }));
    } catch {
      dispatch(updateDownload(id, { status: 'error' }));
      dispatch(addNotification({
        message: `${label}: ${I18n.t('downloads.error')}`,
        type: 'error',
        closable: true
      }));
    }
  };

  return (
    <div className="user-articles__downloads">
      {['csv', 'json'].map(format => (
        <button
          key={format}
          type="button"
          className="button border ghost small"
          onClick={() => download(format)}
        >
          {I18n.t(`downloads.${format}`)}
        </button>
      ))}
    </div>
  );
};

ProfileDownloadButtons.propTypes = {
  username: PropTypes.string.isRequired,
  section: PropTypes.string.isRequired,
  data: PropTypes.object.isRequired
};

export default ProfileDownloadButtons;
