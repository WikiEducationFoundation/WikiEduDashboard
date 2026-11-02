import React from 'react';
import PropTypes from 'prop-types';
import { profileCsv } from '../../utils/user_profile_export';

const ProfileDownloadButtons = ({ username, section, data }) => {
  const download = (format) => {
    const content = format === 'csv' ? profileCsv(data) : JSON.stringify(data, null, 2);
    const mime = format === 'csv' ? 'text/csv;charset=utf-8;' : 'application/json;charset=utf-8;';
    const blob = new Blob([content], { type: mime });
    const url = URL.createObjectURL(blob);
    const safeUsername = username.replace(/[^\p{L}\p{N}_-]/gu, '_');
    const filename = `${safeUsername}_${section}.${format}`;

    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', filename);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
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
