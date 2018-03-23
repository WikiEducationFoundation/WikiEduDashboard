import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from "react-redux";
import UploadTable from './upload_table.jsx';
import { fetchRecentUploads, sortRecentUploads } from '../../actions/recent_uploads_actions.js';


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
