import React from 'react';
import SuspectedPlagiarismStore from '../../stores/suspected_plagiarism_store.coffee';
import ActivityTable from './activity_table.jsx';
import ServerActions from '../../actions/server_actions.js';

const getState = () => {
  return {
    revisions: SuspectedPlagiarismStore.getRevisions(),
    loading: true
  };
};

const PlagiarismHandler = React.createClass({
  displayName: 'PlagiarismHandler',

  mixins: [SuspectedPlagiarismStore.mixin],

  getInitialState() {
    return getState();
  },

  componentWillMount() {
    return ServerActions.fetchSuspectedPlagiarism();
  },

  setCourseScope(e) {
    const scoped = e.target.checked;
    return ServerActions.fetchSuspectedPlagiarism({ scoped });
  },

  storeDidChange() {
    const revisions = getState().revisions;
    return this.setState({ revisions, loading: false });
  },

  render() {
    const headers = [
      { title: 'Article Title', key: 'title' },
      { title: 'Plagiarism Report', key: 'report_url' },
      { title: 'Revision Author', key: 'username' },
      { title: 'Revision Date/Time', key: 'revision_datetime' },
    ];

    const noActivityMessage = I18n.t('recent_activity.no_plagiarism');

    return (
      <div>
        <label>
          <input ref="myCourses" type="checkbox" onChange={this.setCourseScope} />
          {I18n.t('recent_activity.show_courses')}
        </label>
        &nbsp; &nbsp; &nbsp;<a href="/recent-activity/plagiarism/refresh">{I18n.t('recent_activity.refresh_plagiarism')}</a>
        <ActivityTable
          loading={this.state.loading}
          activity={this.state.revisions}
          headers={headers}
          noActivityMessage={noActivityMessage}
        />
      </div>
    );
  }
});

export default PlagiarismHandler;
