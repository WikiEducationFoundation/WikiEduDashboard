import React from 'react';
import PropTypes from 'prop-types';

// Components
import List from '@components/common/list.jsx';
import StudentDrawer from '@components/students/shared/StudentList/StudentDrawer/StudentDrawer.jsx';
import StudentRevisionRow from './StudentRevisionRow';

// Libraries
import CourseUtils from '~/app/assets/javascripts/utils/course_utils.js';
import studentListKeys from '@components/students/shared/StudentList/student_list_keys.js';

export class StudentRevisionsList extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      isOpen: false,
      namespace: 'all'
    };

    this.toggleDrawer = this.toggleDrawer.bind(this);
  }

  onNamespaceChange = (e) => {
    return this.setState({ namespace: e.target.value });
  };

  namespaceToId(nm) {
    const mapping = {
      article: 0,
      talk: 1,
      user: 2
    };
    return mapping[nm];
  }

  _shouldShowRealName() {
    const STUDENT_ROLE = 0;
    const { current_user, student } = this.props;
    const isAdmin = current_user.admin;
    const isNonStudent = current_user.role > STUDENT_ROLE;

    if (!student.real_name) { return false; }
    return current_user && (isAdmin || isNonStudent);
  }

  toggleDrawer() {
    this.setState({ isOpen: !this.state.isOpen });
  }

  render() {
    const {
      course, student, fetchUserRevisions, wikidataLabels, userRevisions
    } = this.props;
    const { isOpen } = this.state;

    if (!userRevisions[student.id]) fetchUserRevisions(course.id, student.id);
    let filteredRevisions = [];
    if (userRevisions[student.id] !== undefined && userRevisions[student.id] !== null) {
      filteredRevisions = (this.state.namespace === 'all')
        ? userRevisions[student.id]
        : userRevisions[student.id].filter((rev) => {
          return rev.article.namespace === this.namespaceToId(this.state.namespace);
        });
    }

    const uploadsLink = `/courses/${course.slug}/uploads`;
    const elements = [
      <StudentRevisionRow
        key={`${student.id}-row`}
        course={course}
        isOpen={isOpen}
        toggleDrawer={this.toggleDrawer}
        student={student}
        uploadsLink={uploadsLink}
      />,
      <StudentDrawer
        key={`${student.id}-drawer`}
        student={student}
        course={course}
        exerciseView={true}
        isOpen={isOpen}
        revisions={filteredRevisions}
        wikidataLabels={wikidataLabels}
      />
    ];

    const {
      recent_revisions, character_sum_ms, references_count, total_uploads
    } = studentListKeys(course);
    const keys = { recent_revisions, character_sum_ms, references_count, total_uploads };

    const filterLabel = <b>Namespace Filter:</b>;
    const filterRevisions = (
      <select
        className="filter-revisions"
        value={this.state.namespace}
        onChange={this.onNamespaceChange}
      >
        <option value="all">All</option>
        <option value="article">Article</option>
        <option value="user">User</option>
        <option value="talk">Talk</option>
      </select>
    );
    return (
      <div className="list__wrapper">
        <h4 className="assignments-list-title">
          {I18n.t('users.revisions')}
          <div className="wrap-filters">
            {filterLabel}
            {filterRevisions}
          </div>
        </h4>
        <List
          elements={elements}
          className="table--expandable table--hoverable"
          keys={keys}
          none_message={CourseUtils.i18n('students_none', course.string_prefix)}
        />
      </div>
    );
  }
}

StudentRevisionsList.propTypes = {
  course: PropTypes.shape({
    id: PropTypes.number.isRequired
  }).isRequired,
  current_user: PropTypes.shape({
    admin: PropTypes.bool,
    role: PropTypes.number
  }).isRequired,
  student: PropTypes.shape({
    id: PropTypes.number.isRequired,
    real_name: PropTypes.string
  }).isRequired,
  fetchUserRevisions: PropTypes.func.isRequired,
  setUploadFilters: PropTypes.func.isRequired,
};

export default StudentRevisionsList;
