import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from "react-redux";
import { fetchRecentUploads, sortRecentUploads } from '../../actions/recent_uploads_actions.js';
import { GALLERY_VIEW } from '../../constants';
import UploadList from '../uploads/upload_list.jsx';


export const RecentUploadsHandlerBase = createReactClass({
  displayName: 'RecentUploadsHandler',

  propTypes: {
    fetchRecentUploads: PropTypes.func,
    sortRecentUploads: PropTypes.func,
    uploads: PropTypes.array,
    loading: PropTypes.bool
   },

  componentWillMount() {
    return this.props.fetchRecentUploads();
  },

  sortBy(e) {
    this.props.sortRecentUploads(e.target.value);
  },

  render() {
    return (
      <div id="uploads">
        <div className="section-header">
          <h3>{I18n.t('uploads.header')}</h3>
          <div className="sort-select">
            <select className="sorts" name="sorts" onChange={this.sortBy}>
              <option value="uploaded_at">{I18n.t('uploads.uploaded_at')}</option>
              <option value="uploader">{I18n.t('uploads.uploaded_by')}</option>
              <option value="usage_count">{I18n.t('uploads.usage_count')}</option>
            </select>
          </div>
        </div>
        <UploadList uploads={this.props.uploads} view={GALLERY_VIEW} />
      </div>
    );
  }
});

const mapStateToProps = state => ({
  uploads: state.recentUploads.uploads
});

const mapDispatchToProps = {
  fetchRecentUploads,
  sortRecentUploads
};

export default connect(mapStateToProps, mapDispatchToProps)(RecentUploadsHandlerBase);
