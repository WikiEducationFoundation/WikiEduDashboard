import React from 'react';
import RecentUploadsStore from '../../stores/recent_uploads_store.coffee';
import UploadTable from './upload_table.jsx';
import ServerActions from '../../actions/server_actions.js';

const getState = () => {
  return {
    uploads: RecentUploadsStore.getUploads(),
    loading: true
  };
};

const RecentUploadsHandler = React.createClass({
  displayName: 'RecentUploadsHandler',

  mixins: [RecentUploadsStore.mixin],

  getInitialState() {
    return getState();
  },

  componentWillMount() {
    return ServerActions.fetchRecentUploads();
  },

  // setCourseScope(e) {
  //   const scoped = e.target.checked;
  //   return ServerActions.fetchRecentEdits({ scoped });
  // },

  storeDidChange() {
    const uploads = getState().uploads;
    return this.setState({ uploads, loading: false });
  },

  render() {
    const headers = [
      { title: 'Image', key: 'image' },
      { title: 'File Name', key: 'file_name' },
      { title: 'Uploaded By', key: 'username' },
      { title: 'Usage Count', key: 'usage_count' },
      { title: 'Date/Time', key: 'date' },
    ];

    return (
      <div>
        <UploadTable
          loading={this.state.loading}
          uploads={this.state.uploads}
          headers={headers}
        />
      </div>
    );
  }
});

export default RecentUploadsHandler;
