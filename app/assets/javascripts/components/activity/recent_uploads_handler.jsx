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
      { title: I18n.t('recent_activity.image'), key: 'image' },
      { title: I18n.t('recent_activity.file_name'), key: 'file_name' },
      { title: I18n.t('recent_activity.uploaded_by'), key: 'username' },
      { title: I18n.t('recent_activity.usage_count'), key: 'usage_count' },
      { title: I18n.t('recent_activity.datetime'), key: 'date' },
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
