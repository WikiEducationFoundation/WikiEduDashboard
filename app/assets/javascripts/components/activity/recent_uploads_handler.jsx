import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from "react-redux";
import { fetchRecentUploads, sortRecentUploads } from '../../actions/recent_uploads_actions.js';
import Loading from '../common/loading.jsx';
import Upload from '../uploads/upload.jsx';


export const UploadTable = createReactClass({
  displayName: 'UploadTable',

  propTypes: {
    loading: PropTypes.bool,
    uploads: PropTypes.array,
  },

  _renderUploads() {
    return this.props.uploads.map((upload) => {
      return (
        <Upload upload={upload} key={upload.id} linkUsername={true} />
      );
    });
  },

  render() {
    if (this.props.loading) {
      return <Loading />;
    }

    const uploads = this._renderUploads();

    return (
      <div className="gallery">
        {uploads}
      </div>
    );
  }
});

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

  // setCourseScope(e) {
  //   const scoped = e.target.checked;
  //   return ServerActions.fetchRecentEdits({ scoped });
  // },

  render() {
    return (
      <div>
        <UploadTable
          loading={this.props.loading}
          uploads={this.props.uploads}
          onSort={this.props.sortRecentUploads}
        />
      </div>
    );
  }
});

const mapStateToProps = state => ({
  uploads: state.recentUploads.uploads,
  loading: state.recentUploads.loading
});

const mapDispatchToProps = {
  fetchRecentUploads,
  sortRecentUploads
};

export default connect(mapStateToProps, mapDispatchToProps)(RecentUploadsHandlerBase);
