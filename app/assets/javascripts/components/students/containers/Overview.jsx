import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

import { toggleUI, resetUI } from '~/app/assets/javascripts/actions';
import { notifyOverdue } from '~/app/assets/javascripts/actions/course_actions';
import { getStudentUsers, editPermissions } from '~/app/assets/javascripts/selectors';

import Controls from '../components/Overview/Controls/Controls.jsx';
import StudentList from '../shared/StudentList/StudentList.jsx';

export class Overview extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showModal: false,
      editAssignments: false
    };

    this.openModal = this.openModal.bind(this);
    this.closeModal = this.closeModal.bind(this);
    this.notify = this.notify.bind(this);
  }

  componentWillUnmount() {
    this.props.resetUI();
  }

  openModal() {
    this.setState({ showModal: true });
  }

  closeModal() {
    this.setState({ showModal: false });
  }

  notify() {
    if (confirm(I18n.t('wiki_edits.notify_overdue.confirm'))) {
      return this.props.notifyOverdue(this.props.course.slug);
    }
  }

  render() {
    const {
      assignments, course, current_user, openKey, sort, students,
      trainingStatus, wikidataLabels, sortUsers, userRevisions,
      sortSelect,
    } = this.props;

    return (
      <div className="list__wrapper">
        {
          current_user.isAdvancedRole
          ? (
            <Controls
              course={course}
              current_user={current_user}
              students={students}
              notify={this.notify}
              sortSelect={sortSelect}
            />
          ) : null
        }

        <StudentList
          assignments={assignments}
          course={course}
          current_user={current_user}
          exerciseView={true}
          openKey={openKey}
          sort={sort}
          sortUsers={sortUsers}
          students={students}
          toggleUI={this.props.toggleUI}
          trainingStatus={trainingStatus}
          userRevisions={userRevisions}
          wikidataLabels={wikidataLabels}
        />
      </div>
    );
  }
}

Overview.propTypes = {
  course: PropTypes.object.isRequired,
  current_user: PropTypes.object.isRequired,
  editPermissions: PropTypes.bool.isRequired,
  students: PropTypes.array,
  openKey: PropTypes.string,
  userRevisions: PropTypes.object.isRequired,
  trainingStatus: PropTypes.object.isRequired,

  notifyOverdue: PropTypes.func.isRequired,
  resetUI: PropTypes.func.isRequired,
  sortSelect: PropTypes.func.isRequired,
  sortUsers: PropTypes.func.isRequired,
  toggleUI: PropTypes.func.isRequired
};

const mapStateToProps = state => ({
  assignments: state.assignments.assignments,

  openKey: state.ui.openKey,
  students: getStudentUsers(state),
  sort: state.users.sort,
  userRevisions: state.userRevisions,
  trainingStatus: state.trainingStatus,
  editPermissions: editPermissions(state),
  wikidataLabels: state.wikidataLabels.labels
});

const mapDispatchToProps = {
  notifyOverdue,
  resetUI,
  toggleUI
};

export default connect(mapStateToProps, mapDispatchToProps)(Overview);
