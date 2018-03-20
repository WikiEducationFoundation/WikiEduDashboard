import React from 'react';
import { connect } from 'react-redux';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import UploadList from './upload_list.jsx';
import { receiveUploads, sortUploads } from '../../actions/uploads_actions.js';

const UploadsHandler = createReactClass({
  displayName: 'UploadsHandler',

  propTypes: {
    course_id: PropTypes.string,
    course: PropTypes.object
  },

  componentWillMount() {
    return this.props.receiveUploads(this.props.course_id);
  },

  sortSelect(e) {
    return this.props.sortUploads(e.target.value);
  },

  render() {
    return (
      <div id="uploads">
        <div className="section-header">
          <h3>{I18n.t('uploads.header')}</h3>
          <div className="sort-select">
            <select className="sorts" name="sorts" onChange={this.sortSelect}>
              <option value="uploaded_at">{I18n.t('uploads.uploaded_at')}</option>
              <option value="file_name">{I18n.t('uploads.file_name')}</option>
              <option value="uploader">{I18n.t('uploads.uploaded_by')}</option>
              <option value="usage_count">{I18n.t('uploads.usage_count')}</option>
            </select>
          </div>
        </div>
        <UploadList course={this.props.course} uploads={this.props.uploads} />
      </div>
    );
  }
}
);

const mapStateToProps = state => ({
  uploads: state.uploads.uploads,
});

const mapDispatchToProps = {
  receiveUploads,
  sortUploads,
};

export default connect(mapStateToProps, mapDispatchToProps)(UploadsHandler);
