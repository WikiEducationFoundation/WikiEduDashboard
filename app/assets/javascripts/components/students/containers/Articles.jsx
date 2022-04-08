import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { generatePath } from 'react-router';
import { Route, Routes } from 'react-router-dom';
import withRouter from '../../util/withRouter';
// Components
import StudentsSubNavigation from '@components/students/components/StudentsSubNavigation.jsx';
import Controls from '@components/students/components/Overview/Controls/Controls.jsx';
import StudentSelection from '@components/students/components/Articles/StudentSelection.jsx';
import SelectedStudent from '@components/students/components/Articles/SelectedStudent/SelectedStudent.jsx';
import NoSelectedStudent from '@components/students/components/Articles/NoSelectedStudent.jsx';

// Actions
import { fetchArticleDetails } from '~/app/assets/javascripts/actions/article_actions.js';
import { fetchTrainingModuleExercisesByUser } from '~/app/assets/javascripts/actions/exercises_actions';
import { fetchUserRevisions } from '~/app/assets/javascripts/actions/user_revisions_actions';
import { setUploadFilters } from '~/app/assets/javascripts/actions/uploads_actions';
import { toggleUI } from '~/app/assets/javascripts/actions';

// Utils
import { getStudentUsers, getWeeksArray } from '~/app/assets/javascripts/selectors';
import { getModulesAndBlocksFromWeeks } from '@components/util/helpers';
import groupArticlesCoursesByUserId from '@components/students/utils/groupArticlesCoursesByUserId';
import ScrollToTopOnMount from '../../util/ScrollToTopOnMount';

export class Articles extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      selected: {}
    };

    this.selectStudent = this.selectStudent.bind(this);
    this.generateArticlesUrl = this.generateArticlesUrl.bind(this);
  }
  componentDidMount() {
    // sets the title of this tab
    const { prefix } = this.props;
    const header = I18n.t('instructor_view.article_assignments', { prefix });
    document.title = `${this.props.course.title} - ${header}`;
  }

  selectStudent(selected) {
    this.setState({ selected });
  }

  generateArticlesUrl(course) {
    const [course_school, course_title] = course.slug.split('/');
    const root = '/courses/:course_school/:course_title/students/articles';
    return generatePath(root, { course_school, course_title });
  }

  render() {
    const {
      articles, assignments, course, current_user, prefix, students, wikidataLabels,
      notify, sortSelect, openKey, sort, trainingStatus, sortUsers, weeks,
      userRevisions
    } = this.props;

    const { modules } = getModulesAndBlocksFromWeeks(weeks);
    const hasExercisesOrTrainings = !!modules.length;
    const groupedArticles = groupArticlesCoursesByUserId(articles);
    if (!students.length) return null;
    const studentSelection = (
      <StudentSelection
        articlesUrl={this.generateArticlesUrl(course)}
        course={course}
        selected={this.state.selected}
        selectStudent={this.selectStudent}
        students={students}
      />
    );
    return (
      <>
        <ScrollToTopOnMount />
        <StudentsSubNavigation
          course={course}
          heading={I18n.t('instructor_view.article_assignments', { prefix })}
          prefix={prefix}
        />
        {
          current_user.isAdvancedRole
            ? (
              <Controls
                course={course}
                current_user={current_user}
                students={students}
                notify={notify}
                showOverviewFilters={false}
                sortSelect={sortSelect}
              />
            ) : null
        }
        <section className="users-articles">
          <aside className="student-selection">
            <Routes>
              <Route
                path=":username" element={studentSelection}
              />
              <Route
                path="*" element={studentSelection}
              />
            </Routes>
          </aside>
          <article className="student-details">
            <section className="assignments">
              <Routes>
                <Route
                  path=":username"
                  element={<SelectedStudent
                    assignments={assignments}
                    course={course}
                    current_user={current_user}
                    fetchArticleDetails={this.props.fetchArticleDetails}
                    fetchUserRevisions={this.props.fetchUserRevisions}
                    groupedArticles={groupedArticles}
                    hasExercisesOrTrainings={hasExercisesOrTrainings}
                    openKey={openKey}
                    setUploadFilters={setUploadFilters}
                    sort={sort}
                    sortUsers={sortUsers}
                    students={students}
                    toggleUI={this.props.toggleUI}
                    trainingStatus={trainingStatus}
                    wikidataLabels={wikidataLabels}
                    userRevisions={userRevisions}
                    articlesUrl={this.generateArticlesUrl(course)}
                  />
                  }
                />
                <Route
                  path="*"
                  element={<NoSelectedStudent string_prefix={course.string_prefix} project={course.home_wiki.project} />}
                />
              </Routes>
            </section>
          </article>
        </section>
      </>
    );
  }
}

Articles.propTypes = {
  articles: PropTypes.array.isRequired,
  assignments: PropTypes.array.isRequired,
  course: PropTypes.object.isRequired,
  current_user: PropTypes.object.isRequired,
  openKey: PropTypes.string,
  prefix: PropTypes.string.isRequired,
  students: PropTypes.array.isRequired,
  wikidataLabels: PropTypes.object,

  sort: PropTypes.object.isRequired,
  sortSelect: PropTypes.func.isRequired,
  sortUsers: PropTypes.func.isRequired,
};

const mapStateToProps = state => ({
  assignments: state.assignments.assignments,
  openKey: state.ui.openKey,
  sort: state.users.sort,
  students: getStudentUsers(state),
  trainingStatus: state.trainingStatus,
  weeks: getWeeksArray(state),
  wikidataLabels: state.wikidataLabels.labels,
  userRevisions: state.userRevisions
});

const mapDispatchToProps = {
  fetchArticleDetails,
  fetchTrainingModuleExercisesByUser,
  fetchUserRevisions,
  setUploadFilters,
  toggleUI
};

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(Articles));
