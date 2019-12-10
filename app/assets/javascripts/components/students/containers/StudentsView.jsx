import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

import { toggleUI, resetUI } from '~/app/assets/javascripts/actions';
import { notifyOverdue } from '~/app/assets/javascripts/actions/course_actions';
import { getStudentUsers, editPermissions } from '~/app/assets/javascripts/selectors';

import Controls from '../components/Controls/Controls.jsx';
import StudentList from '../components/StudentList/StudentList.jsx';

export class StudentsView extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showModal: false,
      editAssignments: false
    };

    this.openModal = this.openModal.bind(this);
    this.closeModal = this.closeModal.bind(this);
    this.toggleAssignmentEditingMode = this.toggleAssignmentEditingMode.bind(this);
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

  toggleAssignmentEditingMode() {
    this.setState({ editAssignments: !this.state.editAssignments });
  }

  notify() {
    if (confirm(I18n.t('wiki_edits.notify_overdue.confirm'))) {
      return this.props.notifyOverdue(this.props.course.slug);
    }
  }

  render() {
    const {
      course, current_user, sortSelect, students
    } = this.props;

    return (
      <div className="list__wrapper">
        {
          editPermissions
          ? (
            <Controls
              course={course}
              current_user={current_user}
              editPermissions={this.state.editPermissions}
              notify={this.notify}
              sortSelect={sortSelect}
              students={students}
              toggleAssignmentEditingMode={this.toggleAssignmentEditingMode}
            />
          ) : null
        }

        <StudentList {...this.props} editAssignments={this.state.editAssignments} />
      </div>
    );
  }
}

StudentsView.propTypes = {
  course_id: PropTypes.string,
  current_user: PropTypes.object,
  students: PropTypes.array,
  course: PropTypes.object,
  editable: PropTypes.bool,
  openKey: PropTypes.string,
  toggleUI: PropTypes.func,
  resetUI: PropTypes.func,
  sortSelect: PropTypes.func,
  sortUsers: PropTypes.func,
  userRevisions: PropTypes.object.isRequired,
  trainingStatus: PropTypes.object.isRequired,
  notifyOverdue: PropTypes.func.isRequired,
  editPermissions: PropTypes.bool.isRequired
};

const mapStateToProps = state => ({
  openKey: state.ui.openKey,
  students: getStudentUsers(state),
  assignments: state.assignments.assignments,
  sort: state.users.sort,
  userRevisions: state.userRevisions,
  trainingStatus: state.trainingStatus,
  editPermissions: editPermissions(state),
  wikidataLabels: state.wikidataLabels.labels
});

const mapDispatchToProps = {
  toggleUI,
  resetUI,
  notifyOverdue
};

export default connect(mapStateToProps, mapDispatchToProps)(StudentsView);
