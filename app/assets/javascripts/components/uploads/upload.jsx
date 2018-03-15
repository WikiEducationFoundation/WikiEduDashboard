import React from 'react';
import PropTypes from 'prop-types';

const Upload = ({ upload, linkUsername }) => {
  let fileName = upload.file_name;
  if (fileName.length > 30) {
    const ellipsis = '…';
    fileName = upload.file_name.substr(0, 30) + ellipsis;
  }

  let imageFile;
  if (upload.deleted) {
    imageFile = '/assets/images/deleted_image.svg';
  } else {
    imageFile = upload.thumburl;
  }

  let uploader;
  if (linkUsername) {
    const profileLink = `/users/${encodeURIComponent(upload.uploader)}`;
    uploader = <a href={profileLink}>{upload.uploader}</a>;
  } else {
    uploader = upload.uploader;
  }

  let usage = '';
  if (upload.usage_count) {
      usage = `${upload.usage_count} usage${upload.usage_count !== 1 ? 's' : ''}`;
  }

  return (
    <div className="upload">
      <a href={upload.url} target="_blank">
        <img src={imageFile} alt="" />
        <div className="info">
          <p className="usage"><b>{usage}</b></p>
          <p><b>{fileName}</b></p>
          <p className="uploader"><b>By <a>{uploader}</a></b></p>
        </div>
      </a>
    </div>
  );
};

Upload.propTypes = {
  upload: PropTypes.object,
  linkUsername: PropTypes.bool
};

export default Upload;
