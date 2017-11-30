import React from 'react';
import PropTypes from 'prop-types';

const Upload = ({ upload, linkUsername }) => {
  let details;
  if (upload.usages > 0) {
    details = (
      <p className="tablet-only">
        <span>{upload.uploader}</span>
        <span>&nbsp;|&nbsp;</span>
        <span>Usages: {upload.usages}</span>
      </p>
    );
  } else {
    details = (
      <p className="tablet-only"><span>{upload.uploader}</span></p>
    );
  }

  let fileName = upload.file_name;
  if (fileName.length > 60) {
    const ellipsis = '…';
    fileName = upload.file_name.substr(0, 60) + ellipsis;
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

  return (
    <tr className="upload">
      <td>
        <a href={upload.url} target="_blank">
          <img src={imageFile} alt="" />
        </a>
        {details}
      </td>
      <td className="desktop-only-tc">
        <a href={upload.url} target="_blank">{fileName}</a>
      </td>
      <td className="desktop-only-tc">{uploader}</td>
      <td className="desktop-only-tc">{upload.usage_count}</td>
      <td className="desktop-only-tc">{moment(upload.uploaded_at).format('YYYY-MM-DD   h:mm A')}</td>
      <td />
    </tr>
  );
};

Upload.propTypes = {
  upload: PropTypes.object,
  linkUsername: PropTypes.bool
};

export default Upload;
