import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import ActivityTable from './activity_table.jsx';
import { fetchDYKArticles, sortDYKArticles } from '../../actions/did_you_know_actions.js';

const NO_ACTIVITY_MESSAGE = I18n.t('recent_activity.no_dyk_eligible');

const HEADERS = [
  { title: I18n.t('recent_activity.article_title'), key: 'title' },
  { title: I18n.t('recent_activity.revision_score'), key: 'revision_score', style: { width: 180 } },
  { title: I18n.t('recent_activity.revision_author'), key: 'username', style: { minWidth: 142 } },
  { title: I18n.t('recent_activity.revision_datetime'), key: 'datetime', style: { width: 200 } }
];

const DidYouKnowHandler = createReactClass({
  displayName: 'DidYouKnowHandler',

  propTypes: {
    fetchDYKArticles: PropTypes.func,
    articles: PropTypes.array,
    loading: PropTypes.bool
  },

  componentDidMount() {
    this.props.fetchDYKArticles();
  },

  setCourseScope(e) {
    const scoped = e.target.checked;
    this.props.fetchDYKArticles({ scoped });
  },

  render() {
    return (
      <div>
        <label>
          <input
            ref="myCourses"
            type="checkbox"
            onChange={this.setCourseScope}
          />
          {I18n.t('recent_activity.show_courses')}
        </label>
        <ActivityTable
          loading={this.props.loading}
          activity={this.props.articles}
          headers={HEADERS}
          noActivityMessage={NO_ACTIVITY_MESSAGE}
          onSort={this.props.sortDYKArticles}
        />
      </div>
    );
  }
});

const mapStateToProps = state => ({
  articles: state.didYouKnow.articles,
  loading: state.didYouKnow.loading
});

const mapDispatchToProps = {
  fetchDYKArticles: fetchDYKArticles,
  sortDYKArticles: sortDYKArticles
};

export default connect(mapStateToProps, mapDispatchToProps)(DidYouKnowHandler);
