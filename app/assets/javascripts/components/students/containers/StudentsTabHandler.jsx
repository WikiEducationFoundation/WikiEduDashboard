import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { Navigate, Route, Routes } from 'react-router-dom';
import withRouter from '../../util/withRouter';
// Components
import Loading from '@components/common/loading.jsx';
import Overview from './Overview';
import Articles from './Articles';

// Actions
import { notifyOverdue } from '~/app/assets/javascripts/actions/course_actions';
import { sortUsers } from '~/app/assets/javascripts/actions/user_actions';
import { fetchAssignments } from '~/app/assets/javascripts/actions/assignment_actions';
import { fetchArticles } from '~/app/assets/javascripts/actions/articles_actions.js';

// Utils
import CourseUtils from '~/app/assets/javascripts/utils/course_utils.js';
import { getArticlesByNewness } from '~/app/assets/javascripts/selectors';
import { delayFetchAssignmentsAndArticles } from '@components/util/helpers';

const StudentsTabHandler = createReactClass({
  displayName: 'StudentsTabHandler',

  propTypes: {
    course_id: PropTypes.string,
    current_user: PropTypes.object,
    course: PropTypes.object,
    sortUsers: PropTypes.func.isRequired,
    fetchAssignments: PropTypes.func.isRequired,
    loadingAssignments: PropTypes.bool
  },

  getInitialState() {
    return { loading: true };
  },

  componentDidMount() {
    delayFetchAssignmentsAndArticles(this.props, () => this.setState({ loading: false }));
  },

  notify() {
    if (confirm(I18n.t('wiki_edits.notify_overdue.confirm'))) {
      return this.props.notifyOverdue(this.props.course.slug);
    }
  },

  sortSelect(e) {
    return this.props.sortUsers(e.target.value);
  },

  render() {
    if (this.state.loading) return <Loading />;

    const prefix = CourseUtils.i18n('students', this.props.course.string_prefix);
    const props = {
      ...this.props,
      prefix,
      notify: this.notify,
      sortSelect: this.sortSelect
    };
    return (
      <div id="users">
        <Routes>
          <Route path="overview/*" element={<Overview {...props} />} />
          <Route path="articles/*" element={<Articles {...props} />} />
          <Route path="*" element={<Navigate replace to="overview"/>} />
        </Routes>
      </div>
    );
  }
}
);

const mapStateToProps = state => ({
  articles: getArticlesByNewness(state),
  course: state.course,
  limit: state.articles.limit,
  loadingAssignments: state.assignments.loading,
  loadingArticles: state.articles.loading,
  wikidataLabels: state.wikidataLabels.labels,
});

const mapDispatchToProps = {
  notifyOverdue,
  sortUsers,
  fetchAssignments,
  fetchArticles
};

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(StudentsTabHandler));
