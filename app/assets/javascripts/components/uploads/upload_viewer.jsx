import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { useDispatch, useSelector } from 'react-redux';
import { setUploadViewerMetadata, setUploadPageViews, resetUploadsViews } from '../../actions/uploads_actions.js';
import { formatDateWithoutTime } from '../../utils/date_utils.js';
import { forEach, get } from 'lodash-es';
import OnClickOutside from 'react-onclickoutside';

const UploadViewer = ({ closeUploadViewer, upload, imageFile }) => {
  const dispatch = useDispatch();
  const uploadMetadata = useSelector(state => state.uploads.uploadMetadata);
  const pageViews = useSelector(state => state.uploads.averageViews);

  const [loadingViews, setLoadingViews] = useState(true);

  useEffect(() => {
    dispatch(setUploadViewerMetadata(upload));
    return () => {
      dispatch(resetUploadsViews());
    };
  }, [upload]);

  useEffect(() => {
    const metadata = get(uploadMetadata, `query.pages[${upload.id}]`);
    const fileUsage = get(metadata, 'globalusage', []);
    if (fileUsage && loadingViews) {
      handleGetFileViews(fileUsage);
    }
  }, [uploadMetadata, upload.id, loadingViews]);

  const handleGetFileViews = files => {
    dispatch(setUploadPageViews(files));
    setLoadingViews(false);
  };

  const handleClickOutside = () => {
    closeUploadViewer();
  };

  const metadata = get(uploadMetadata, `query.pages[${upload.id}]`);
  const imageDescription = get(metadata, 'imageinfo[0].extmetadata.ImageDescription.value');
  const width = get(metadata, 'imageinfo[0].width');
  const height = get(metadata, 'imageinfo[0].height');

  let size = get(metadata, 'imageinfo[0].size');
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
  const i = Math.floor(Math.log(size) / Math.log(1024));
  size = `${parseFloat((size / (1024 ** i)).toFixed(2))} ${sizes[i]}`;

  const imageUrl = get(metadata, 'imageinfo[0].url');

  const profileLink = `/users/${encodeURIComponent(upload.uploader)}`;
  const author = <a href={profileLink} target="_blank">{upload.uploader}</a>;
  const source = get(metadata, 'imageinfo[0].extmetadata.Credit.value');
  const license = get(metadata, 'imageinfo[0].extmetadata.LicenseShortName.value');
  const globalUsage = get(metadata, 'globalusage', []);
  let usageTableElements;
  if (globalUsage && pageViews !== undefined) {
    usageTableElements = globalUsage.map((usage, index) => {
        return (
          <tr className="view-file-details" key={usage.url}>
            <td className="row-details">{usage.wiki}&nbsp;&nbsp;&nbsp;</td>
            <td className="row-details"><a href={usage.url}>{usage.title}</a>&nbsp;&nbsp;&nbsp;</td>
            <td className="text-right row-details">{pageViews[index]}</td>
          </tr>
        );
    });
  }

  let fileUsageTable;
  if (globalUsage.length > 0) {
    fileUsageTable = (
      <div>
        <h1>{'\n'}</h1>
        <h4>File usage on other wikis</h4>
        <table border="1">
          <thead>
            <tr>
              <th>Wiki</th>
              <th>Article Name</th>
              <th>Views per day</th>
            </tr>
          </thead>
          <tbody>
            {usageTableElements}
          </tbody>
        </table>
      </div>
    );
  }
  let categoriesList = [];
  let categories;
  forEach(get(metadata, 'categories', []), (category) => {
    categoriesList.push(<span key={`span-${category.title}`}> | </span>);
    categoriesList.push(<a href={`https://commons.wikimedia.org/wiki/${category.title}`} target="_blank" key={`link-${category.title}`}>{category.title.slice('Category:'.length)}</a>);
  });
  if (categoriesList.length > 0) {
    categoriesList = categoriesList.splice(1);
    categories = (
      <div>
        <h1>{'\n'}</h1>
        <h4>Categories</h4>
        {categoriesList}
      </div>
    );
  }

  return (
    <div className="module upload-viewer">
      <div className="modal-header">
        <button className="pull-right icon-close" onClick={handleClickOutside} />
        <h3>{upload.file_name}</h3>
      </div>
      <div className="modal-body">
        <div className="left">
          <a href={upload.url} target="_blank"><img alt={upload.file_name} src={imageFile} /></a>
          <p><a href={imageUrl} target="_blank">Original File</a>{` (${width} X ${height} pixels, file size: ${size})`}</p>
          <h4>Description</h4>
          <p dangerouslySetInnerHTML={{ __html: imageDescription }} />
        </div>
        <div className="right">
          <table className="view-file-details">
            <tbody>
              <tr>
                <td className="row-details bg-grey">Date:&nbsp;</td>
                <td className="row-details">{formatDateWithoutTime(upload.uploaded_at)}</td>
              </tr>
              <tr>
                <td className="row-details bg-grey">Author:&nbsp;</td>
                <td className="row-details">{author}</td>
              </tr>
              <tr>
                <td className="row-details bg-grey">Source:&nbsp;</td>
                <td className="row-details" dangerouslySetInnerHTML={{ __html: source }} />
              </tr>
              <tr>
                <td className="row-details bg-grey">License:&nbsp;</td>
                <td className="row-details">{license}</td>
                <td>{'\n'}</td>
              </tr>
            </tbody>
          </table>
          {categories}
          {fileUsageTable}
        </div>
      </div>
      <div className="modal-footer">
        <a className="button dark small pull-right upload-viewer-button" href={upload.url} target="_blank">View on Commons</a>
      </div>
    </div>
  );
};

UploadViewer.propTypes = {
  upload: PropTypes.object,
  closeUploadViewer: PropTypes.func,
  imageFile: PropTypes.string
};

export default OnClickOutside(UploadViewer);
