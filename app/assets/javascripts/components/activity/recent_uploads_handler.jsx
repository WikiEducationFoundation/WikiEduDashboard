import React from 'react';
import createReactClass from 'create-react-class';
import RecentUploadsStore from '../../stores/recent_uploads_store.js';
import UploadTable from './upload_table.jsx';
import ServerActions from '../../actions/server_actions.js';

const getState = () => {
  return {
    uploads: RecentUploadsStore.getUploads(),
    loading: true
  };
};

const RecentUploadsHandler = createReactClass({
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
      { title: I18n.t('recent_activity.uploaded_by'), key: 'username', style: { minWidth: 142 } },
      { title: I18n.t('recent_activity.usage_count'), key: 'usage_count', style: { width: 130 } },
      { title: I18n.t('recent_activity.datetime'), key: 'date', style: { width: 200 } },
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
