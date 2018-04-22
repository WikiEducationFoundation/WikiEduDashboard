import React from 'react';
import PropTypes from 'prop-types';

const Upload = ({ upload, linkUsername }) => {
  const fileName = upload.file_name;

  let imageFile;
  if (upload.deleted) {
    imageFile = '/assets/images/deleted_image.svg';
  } else {
    imageFile = upload.thumburl;
  }

  let uploader;
  if (linkUsername) {
    const profileLink = `/users/${encodeURIComponent(upload.uploader)}`;
    uploader = <a href={profileLink} target="_blank">{upload.uploader}</a>;
  } else {
    uploader = upload.uploader;
  }

  let usage = '';
  if (upload.usage_count) {
      usage = `${upload.usage_count} ${I18n.t('uploads.usage_count')}`;
    }

  return (
    <div className="upload">
      <img src={imageFile} alt="" />
      <div className="info">
        <p className="usage"><b>{usage}</b></p>
        <p><b><a href={upload.url} target="_blank">{fileName}</a></b></p>
        <p className="uploader"><b>{I18n.t('uploads.uploaded_by')} {uploader}</b></p>
      </div>
    </div>
  );
};

Upload.propTypes = {
  upload: PropTypes.object,
  linkUsername: PropTypes.bool
};

export default Upload;
