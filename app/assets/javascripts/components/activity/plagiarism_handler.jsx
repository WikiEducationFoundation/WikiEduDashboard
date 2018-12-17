import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import ActivityTable from './activity_table.jsx';
import { fetchSuspectedPlagiarism, sortSuspectedPlagiarism } from '../../actions/suspected_plagiarism_actions.js';

const HEADERS = [
      { title: I18n.t('recent_activity.article_title'), key: 'title' },
      { title: I18n.t('recent_activity.plagiarism_report'), key: 'report_url', style: { width: 180 } },
      { title: I18n.t('recent_activity.revision_author'), key: 'username', style: { minWidth: 142 } },
      { title: I18n.t('recent_activity.revision_datetime'), key: 'datetime', style: { width: 200 } },
    ];

const NO_ACTIVITY_MESSAGE = I18n.t('recent_activity.no_plagiarism');


const PlagiarismHandler = createReactClass({
  displayName: 'PlagiarismHandler',

  propTypes: {
    fetchSuspectedPlagiarism: PropTypes.func,
    revisions: PropTypes.array,
    loading: PropTypes.bool
  },

  componentWillMount() {
    return this.props.fetchSuspectedPlagiarism();
  },

  setCourseScope(e) {
    const scoped = e.target.checked;
    return this.props.fetchSuspectedPlagiarism({ scoped });
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
          onSort={this.props.sortSuspectedPlagiarism}
        />
      </div>
    );
  }
});


const mapStateToProps = state => ({
  revisions: state.suspectedPlagiarism.revisions,
  loading: state.suspectedPlagiarism.loading
});

const mapDispatchToProps = {
  fetchSuspectedPlagiarism: fetchSuspectedPlagiarism,
  sortSuspectedPlagiarism: sortSuspectedPlagiarism
};

export default connect(mapStateToProps, mapDispatchToProps)(PlagiarismHandler);
