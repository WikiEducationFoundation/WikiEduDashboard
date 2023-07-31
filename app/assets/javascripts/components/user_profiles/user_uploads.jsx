import React from 'react';
import PropTypes from 'prop-types';
import { GALLERY_VIEW } from '../../constants';
import UploadList from '../uploads/upload_list.jsx';


const UserUploads = ({ uploads }) => {
  let uploadList = (<UploadList uploads={uploads} view={GALLERY_VIEW} />);
  if (uploads.length === 0) {
    uploadList = (<span>{I18n.t('courses.user_uploads_none')}</span>);
  }
  return (
    <div id="recent-uploads">
      <h3>Recent Uploads</h3>
      {uploadList}
    </div>
  );
};

UserUploads.propTypes = {
  uploads: PropTypes.array
};

export default UserUploads;
