import React, { useEffect, useState } from 'react';
import { LIST_VIEW, GALLERY_VIEW, TILE_VIEW } from '../../constants';
import UploadViewer from './upload_viewer.jsx';
import Modal from '../common/modal.jsx';
import PropTypes from 'prop-types';
import { formatDateWithTime } from '../../utils/date_utils';

const Upload = ({ upload, view, linkUsername }) => {
  const [width, setWidth] = useState(null);
  const [height, setHeight] = useState(null);
  const [isUploadViewerOpen, setIsUploadViewerOpen] = useState(false);
  const [imageFile, setImageFile] = useState(null);

  useEffect(() => {
    updateImageFile();
  }, []);

  const updateImageFile = () => {
    let file = upload.thumburl;
    if (upload.deleted) {
      file = '/assets/images/deleted_image.svg';
    }
    setImageFile(file);
    setImageDimensions(file);
  };

  const setImageDimensions = (file) => {
    const img = new Image();
    img.src = file;
    img.onload = function () {
      setWidth(this.width);
      setHeight(this.height);
    };
  };

  const toggleUploadViewer = () => {
    setIsUploadViewerOpen(!isUploadViewerOpen);
  };

  let fileName = upload.file_name;
  if (fileName.length > 50) {
    fileName = `${fileName.substring(0, 50)}...`;
  }
  let uploader;
  if (linkUsername) {
    const profileLink = `/users/${encodeURIComponent(upload.uploader)}`;
    uploader = <a href={profileLink} onClick={event => event.stopPropagation()} target="_blank">{upload.uploader}</a>;
  } else {
    uploader = upload.uploader;
  }

  let usage = '';
  if (upload.usage_count) {
    usage = `${I18n.t('uploads.usage_count_gallery_tile', { usage_count: upload.usage_count })}`;
  }

  let uploadDivStyle;
  if (width && height) {
    uploadDivStyle = {
      width: (width * 250) / height,
      flexGrow: (width * 250) / height,
    };
  }

  let details;
  if (upload.usage_count > 0) {
    details = (
      <p className="tablet-only">
        <span>{upload.uploader}</span>
        <span>&nbsp;|&nbsp;</span>
        <span>Usages: {upload.usage_count}</span>
      </p>
    );
  } else {
    details = (
      <p className="tablet-only"><span>{upload.uploader}</span></p>
    );
  }

  if (isUploadViewerOpen) {
    if (view === LIST_VIEW) {
      return (
        <tr>
          <td>
            <Modal>
              <UploadViewer closeUploadViewer={toggleUploadViewer} upload={upload} imageFile={imageFile} />
            </Modal>
          </td>
        </tr>
      );
    }
    return (
      <Modal>
        <UploadViewer closeUploadViewer={toggleUploadViewer} upload={upload} imageFile={imageFile} />
      </Modal>
    );
  }


  if (view === LIST_VIEW) {
    usage = `${upload.usage_count} ${I18n.t('uploads.usage_count')}`;
    return (
      <tr className="upload list-view" onClick={toggleUploadViewer}>
        <td>
          <img src={imageFile} alt={fileName} />
          {details}
        </td>
        <td className="desktop-only-tc">
          <a onClick={event => event.stopPropagation()} href={upload.url} target="_blank">{fileName}</a>
        </td>
        <td className="desktop-only-tc">{uploader}</td>
        <td className="desktop-only-tc">{upload.usage_count}</td>
        <td className="desktop-only-tc">{formatDateWithTime(upload.uploaded_at)}</td>
        <td className="desktop-only-tc">{<span dangerouslySetInnerHTML={{ __html: upload.credit }} /> || <img className="credit-loading" src={'/assets/images/loader.gif'} alt="loading credits" />}</td>
      </tr>
    );
  } else if (view === GALLERY_VIEW) {
    return (
      <div className="upload" style={uploadDivStyle} onClick={toggleUploadViewer} >
        <img src={imageFile} alt={fileName} />
        <div className="info">
          <p className="usage"><b>{usage}</b></p>
          <p><b><a href={upload.url} target="_blank" onClick={event => event.stopPropagation()}>{fileName}</a></b></p>
          <p className="uploader"><b>{I18n.t('uploads.uploaded_by')} {uploader}</b></p>
          <p><b>{I18n.t('uploads.uploaded_on')}</b>&nbsp;{formatDateWithTime(upload.uploaded_at)}</p>
        </div>
      </div>
    );
  } else if (view === TILE_VIEW) {
    return (
      <div className="tile-container" onClick={toggleUploadViewer}>
        <div className="tile">
          <img src={imageFile} alt={fileName} />
          <div className="info">
            <p className="usage"><b>{usage}</b></p>
            <p><b><a href={upload.url} target="_blank" onClick={event => event.stopPropagation()}>{fileName}</a></b></p>
            <p className="uploader"><b>{I18n.t('uploads.uploaded_by')} {uploader}</b></p>
            <p>
              <b>{I18n.t('uploads.uploaded_on')}</b>&nbsp;{formatDateWithTime(upload.uploaded_at)}
            </p>
          </div>
        </div>
      </div>
    );
  }
};

Upload.propTypes = {
  upload: PropTypes.object,
  linkUsername: PropTypes.bool,
};

export default Upload;
