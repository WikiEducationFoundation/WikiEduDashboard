import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

import { getStudentUsers, editPermissions } from '~/app/assets/javascripts/selectors';

import StudentsSubNavigation from '@components/students/components/StudentsSubNavigation.jsx';
import Controls from '@components/students/components/Overview/Controls/Controls.jsx';
import StudentList from '../shared/StudentList/StudentList.jsx';
import RandomPeerAssignButton from '@components/students/components/RandomPeerAssignButton.jsx';
import Loading from '@components/common/loading.jsx';
import AddToWatchlistButton from '@components/students/components/AddToWatchlistButton.jsx';

export class Overview extends React.Component {
  componentDidMount() {
    // sets the title of this tab
    const { prefix } = this.props;
    const header = I18n.t('users.sub_navigation.student_overview', { prefix });
    document.title = `${this.props.course.title} - ${header}`;
  }

  render() {
    const {
      assignments, course, current_user, prefix, sort, students,
      trainingStatus, wikidataLabels, sortUsers, userRevisions,
      notify, sortSelect
    } = this.props;

    return (
      <div className="list__wrapper">
        <StudentsSubNavigation
          course={course}
          heading={I18n.t('instructor_view.overview', { prefix })}
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
              sortSelect={sortSelect}
            />
          ) : null
        }

        <div className="action-buttons-container">
          <RandomPeerAssignButton {...this.props} />
          { current_user.isAdvancedRole ? (<AddToWatchlistButton slug={course.slug} prefix={prefix} />) : null }
        </div>

        { this.props.loadingAssignments && <Loading /> }

        { !this.props.loadingAssignments && (
          <StudentList
            assignments={assignments}
            course={course}
            current_user={current_user}
            sort={sort}
            sortUsers={sortUsers}
            students={students}
            trainingStatus={trainingStatus}
            userRevisions={userRevisions}
            wikidataLabels={wikidataLabels}
          />)}
      </div>
    );
  }
}

Overview.propTypes = {
  course: PropTypes.object.isRequired,
  current_user: PropTypes.object.isRequired,
  editPermissions: PropTypes.bool.isRequired,
  prefix: PropTypes.string.isRequired,
  students: PropTypes.array,
  openKey: PropTypes.string,
  userRevisions: PropTypes.object.isRequired,
  trainingStatus: PropTypes.object.isRequired,

  notifyOverdue: PropTypes.func.isRequired,
  sort: PropTypes.object.isRequired,
  sortSelect: PropTypes.func.isRequired,
  sortUsers: PropTypes.func.isRequired
};

const mapStateToProps = state => ({
  assignments: state.assignments.assignments,
  loadingAssignments: state.assignments.loading,

  openKey: state.ui.openKey,
  students: getStudentUsers(state),
  sort: state.users.sort,
  userRevisions: state.userRevisions,
  trainingStatus: state.trainingStatus,
  editPermissions: editPermissions(state),
  wikidataLabels: state.wikidataLabels.labels
});

export default connect(mapStateToProps)(Overview);
