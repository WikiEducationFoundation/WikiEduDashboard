import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { useDispatch, useSelector } from 'react-redux';
import { fetchRecentUploads, sortRecentUploads } from '../../actions/recent_uploads_actions.js';
import { GALLERY_VIEW } from '../../constants';
import UploadList from '../uploads/upload_list.jsx';


const RecentUploadsHandlerBase = () => {
  const dispatch = useDispatch();
  const uploads = useSelector(state => state.recentUploads.uploads);

  useEffect(() => {
    dispatch(fetchRecentUploads());
  }, []);

  const sortBy = (e) => {
    dispatch(sortRecentUploads(e.target.value));
  };

  return (
    <div id="uploads">
      <div className="section-header">
        <h3>{I18n.t('uploads.header')}</h3>
        <div className="sort-select">
          <select className="sorts" name="sorts" onChange={sortBy}>
            <option value="uploaded_at">{I18n.t('uploads.uploaded_at')}</option>
            <option value="uploader">{I18n.t('uploads.uploaded_by')}</option>
            <option value="usage_count">{I18n.t('uploads.usage_count')}</option>
          </select>
        </div>
      </div>
      <UploadList uploads={uploads} view={GALLERY_VIEW} />
    </div>
  );
};

RecentUploadsHandlerBase.propTypes = {
  fetchRecentUploads: PropTypes.func,
  sortRecentUploads: PropTypes.func,
  uploads: PropTypes.array,
  loading: PropTypes.bool
};

export default (RecentUploadsHandlerBase);
