import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { getStudentUsers } from '~/app/assets/javascripts/selectors';

// Components
import StudentsSubNavigation from '@components/students/components/StudentsSubNavigation.jsx';
import StudentSelection from '@components/students/components/Articles/StudentSelection.jsx';
import SelectedStudent from '@components/students/components/Articles/SelectedStudent/SelectedStudent.jsx';
import NoSelectedStudent from '@components/students/components/Articles/NoSelectedStudent.jsx';

export class Articles extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      selected: null
    };

    this.selectStudent = this.selectStudent.bind(this);
  }

  selectStudent(selected) {
    this.setState({ selected });
  }

  render() {
    const { selected } = this.state;
    const {
      assignments, course, current_user, prefix, students, wikidataLabels
    } = this.props;

    return (
      <>
        <StudentsSubNavigation
          course={course}
          heading={I18n.t('instructor_view.exercises_and_trainings', { prefix })}
        />
        <section className="users-articles">
          <aside className="student-selection">
            <StudentSelection
              selected={this.state.selected}
              selectStudent={this.selectStudent}
              students={students}
            />
          </aside>
          <article className="student-details">
            <section className="assignments">
              {
                selected
                ? (
                  <SelectedStudent
                    assignments={assignments}
                    course={course}
                    current_user={current_user}
                    selected={selected}
                    wikidataLabels={wikidataLabels}
                  />
                ) : <NoSelectedStudent string_prefix={course.string_prefix} />
              }
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

const mapDispatchToProps = null;

export default connect(mapStateToProps, mapDispatchToProps)(Articles);
