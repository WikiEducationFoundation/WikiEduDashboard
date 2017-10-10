import React from 'react';
import createReactClass from 'create-react-class';
import RecentEditsStore from '../../stores/recent_edits_store.js';
import ActivityTable from './activity_table.jsx';
import ServerActions from '../../actions/server_actions.js';

const getState = () => {
  return {
    revisions: RecentEditsStore.getRevisions(),
    loading: true
  };
};

const RecentEditsHandler = createReactClass({
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
      { title: I18n.t('recent_activity.article_title'), key: 'title' },
      { title: I18n.t('recent_activity.revision_score'), key: 'revision_score', style: { width: 142 } },
      { title: I18n.t('recent_activity.revision_author'), key: 'username', style: { minWidth: 142 } },
      { title: I18n.t('recent_activity.revision_datetime'), key: 'revision_datetime', style: { width: 200 } },
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
