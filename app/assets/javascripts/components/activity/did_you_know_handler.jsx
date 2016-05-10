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
    const headers = [
      { title: I18n.t('recent_activity.article_title'), key: 'title' },
      { title: I18n.t('recent_activity.revision_score'), key: 'revision_score' },
      { title: I18n.t('recent_activity.revision_author'), key: 'username' },
      { title: I18n.t('recent_activity.revision_datetime'), key: 'revision_datetime' },
    ];

    const noActivityMessage = I18n.t('recent_activity.no_dyk_eligible');

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
