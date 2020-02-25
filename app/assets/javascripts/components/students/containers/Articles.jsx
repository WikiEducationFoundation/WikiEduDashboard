import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { getStudentUsers } from '~/app/assets/javascripts/selectors';
import { Route, Switch } from 'react-router-dom';

// Components
import StudentsSubNavigation from '@components/students/components/StudentsSubNavigation.jsx';
import Controls from '@components/students/components/Overview/Controls/Controls.jsx';
import StudentSelection from '@components/students/components/Articles/StudentSelection.jsx';
import SelectedStudent from '@components/students/components/Articles/SelectedStudent/SelectedStudent.jsx';
import NoSelectedStudent from '@components/students/components/Articles/NoSelectedStudent.jsx';

// Actions
import { fetchArticleDetails } from '~/app/assets/javascripts/actions/article_actions.js';

export class Articles extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      selected: {}
    };

    this.selectStudent = this.selectStudent.bind(this);
  }

  selectStudent(selected) {
    this.setState({ selected });
  }

  render() {
    const {
      assignments, course, current_user, prefix, students, wikidataLabels,
      notify, sortSelect
    } = this.props;

    if (!students.length) return null;
    return (
      <>
        <StudentsSubNavigation
          course={course}
          heading={I18n.t('instructor_view.exercises_and_trainings', { prefix })}
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
            <StudentSelection
              course={course}
              selected={this.state.selected}
              selectStudent={this.selectStudent}
              students={students}
            />
          </aside>
          <article className="student-details">
            <section className="assignments">
              <Switch>
                <Route
                  exact
                  path="/courses/:course_school/:course_title/students/articles/:username"
                  render={({ match }) => {
                    const selected = students.find(({ username }) => username === match.params.username);
                    return (
                      <SelectedStudent
                        assignments={assignments}
                        course={course}
                        current_user={current_user}
                        fetchArticleDetails={this.props.fetchArticleDetails}
                        selected={selected}
                        selectStudent={this.selectStudent}
                        wikidataLabels={wikidataLabels}
                      />
                    );
                  }}
                />
                <Route
                  exact
                  path="/courses/:course_school/:course_title/students/articles"
                  render={() => <NoSelectedStudent string_prefix={course.string_prefix} />}
                />
              </Switch>
            </section>
          </article>
        </section>
      </>
    );
  }
}

Articles.propTypes = {
  assignments: PropTypes.array.isRequired,
  current_user: PropTypes.object.isRequired,
  students: PropTypes.array.isRequired,
  wikidataLabels: PropTypes.object
};

const mapStateToProps = state => ({
  students: getStudentUsers(state),
  assignments: state.assignments.assignments,
  wikidataLabels: state.wikidataLabels.labels
});

const mapDispatchToProps = {
  fetchArticleDetails
};

export default connect(mapStateToProps, mapDispatchToProps)(Articles);
