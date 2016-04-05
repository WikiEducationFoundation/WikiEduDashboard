import React from 'react';
import DidYouKnowStore from '../../stores/did_you_know_store.coffee';
import ActivityTable from './activity_table.jsx';
import ServerActions from '../../actions/server_actions.js';

const getState = () => {
  return {
    articles: DidYouKnowStore.getArticles(),
    loading: true
  };
};

const DidYouKnowHandler = React.createClass({
  displayName: 'DidYouKnowHandler',

  mixins: [DidYouKnowStore.mixin],

  getInitialState() {
    return getState();
  },

  componentWillMount() {
    ServerActions.fetchDYKArticles();
  },

  setCourseScope(e) {
    const scoped = e.target.checked;
    ServerActions.fetchDYKArticles({ scoped });
  },

  storeDidChange() {
    const articles = getState().articles;
    this.setState({ articles, loading: false });
  },

  render() {
    let headers = [
      { title: 'Article Title', key: 'title' },
      { title: 'Revision Score', key: 'revision_score' },
      { title: 'Revision Author', key: 'username' },
      { title: 'Revision Date/Time', key: 'revision_datetime' },
    ];

    let noActivityMessage = I18n.t('recent_activity.no_dyk_eligible');

    return (
      <div>
        <label>
          <input ref="myCourses" type="checkbox" onChange={this.setCourseScope} />
          {I18n.t('recent_activity.show_courses')}
        </label>
        <ActivityTable
          loading={this.state.loading}
          activity={this.state.articles}
          headers={headers}
          noActivityMessage={noActivityMessage}
        />
      </div>
    );
  }
});


export default DidYouKnowHandler;
