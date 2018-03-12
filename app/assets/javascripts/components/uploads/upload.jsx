import React from 'react';
import PropTypes from 'prop-types';

const Upload = ({ upload, linkUsername }) => {
  let fileName = upload.file_name;
  if (fileName.length > 20) {
    const ellipsis = '…';
    fileName = upload.file_name.substr(0, 20) + ellipsis;
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

  let usageCount = upload.usage_count; 
  if (usageCount === 0 ) {
    usageCount = '';
  } else if (usageCount === 1) {
    usageCount = usageCount + 'usage';
  } else {
    usageCount = usageCount + 'usages'; 
  }

  return (
    <tr><td>
      <div className="gallery">
        <div className="upload">
          <a href={upload.url} target="_blank">
          <img src={imageFile} alt="" />
          <div className="info">
            <p className="count">{usageCount}</p> 
            <p>{uploader}</p>
            <p>{fileName}</p>
          </div>
          </a>
        </div>
      </div>
    </td></tr>
  );
};

Upload.propTypes = {
  upload: PropTypes.object,
  linkUsername: PropTypes.bool
};

export default Upload;
