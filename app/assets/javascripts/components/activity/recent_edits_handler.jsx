import React from 'react';
import RecentEditsStore from '../../stores/recent_edits_store.coffee';
import ActivityTable from './activity_table.jsx';
import ServerActions from '../../actions/server_actions.js';

const getState = () => {
  return {
    revisions: RecentEditsStore.getRevisions(),
    loading: true
  };
};

const RecentEditsHandler = React.createClass({
  displayName: 'RecentEditsHandler',

  mixins: [RecentEditsStore.mixin],

  getInitialState() {
    return getState();
  },

  componentWillMount() {
    return ServerActions.fetchRecentEdits();
  },

  setCourseScope(e) {
    const scoped = e.target.checked;
    return ServerActions.fetchRecentEdits({ scoped });
  },

  storeDidChange() {
    const revisions = getState().revisions;
    return this.setState({ revisions, loading: false });
  },

  render() {
    const headers = [
      { title: 'Article Title', key: 'title' },
      { title: 'Revision Score', key: 'revision_score' },
      { title: 'Revision Author', key: 'username' },
      { title: 'Revision Date/Time', key: 'revision_datetime' },
    ];

    const noActivityMessage = I18n.t('recent_activity.no_edits');

    return (
      <div>
        <label>
          <input ref="myCourses" type="checkbox" onChange={this.setCourseScope} />
          {I18n.t('recent_activity.show_courses')}
        </label>
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

export default RecentEditsHandler;
