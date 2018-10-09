import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import ActivityTable from './activity_table.jsx';
import { fetchRecentEdits, sortRecentEdits } from '../../actions/recent_edits_actions.js';

const NO_ACTIVITY_MESSAGE = I18n.t('recent_activity.no_edits');

const HEADERS = [
      { title: I18n.t('recent_activity.article_title'), key: 'title' },
      { title: I18n.t('recent_activity.revision_score'), key: 'revision_score', style: { width: 180 } },
      { title: I18n.t('recent_activity.revision_author'), key: 'username', style: { minWidth: 142 } },
      { title: I18n.t('recent_activity.revision_datetime'), key: 'datetime', style: { width: 200 } },
];

const RecentEditsHandler = createReactClass({
  displayName: 'RecentEditsHandler',

  propTypes: {
    fetchRecentEdits: PropTypes.func,
    sortRecentEdits: PropTypes.func,
    revisions: PropTypes.array,
    loading: PropTypes.bool
  },

  componentWillMount() {
    return this.props.fetchRecentEdits();
  },

  setCourseScope(e) {
    const scoped = e.target.checked;
    this.props.fetchRecentEdits({ scoped });
  },

  render() {
    return (
      <div>
        <label>
          <input ref="myCourses" type="checkbox" onChange={this.setCourseScope} />
          {I18n.t('recent_activity.show_courses')}
        </label>
        <ActivityTable
          loading={this.props.loading}
          activity={this.props.revisions}
          headers={HEADERS}
          noActivityMessage={NO_ACTIVITY_MESSAGE}
          onSort={this.props.sortRecentEdits}
        />
      </div>
    );
  }
});

const mapStateToProps = state => ({
  revisions: state.recentEdits.revisions,
  loading: state.recentEdits.loading
});

const mapDispatchToProps = {
  fetchRecentEdits: fetchRecentEdits,
  sortRecentEdits: sortRecentEdits
};

export default connect(mapStateToProps, mapDispatchToProps)(RecentEditsHandler);
