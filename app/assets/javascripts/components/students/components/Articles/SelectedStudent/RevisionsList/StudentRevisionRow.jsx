import React from 'react';
import { Link } from 'react-router-dom';
import PropTypes from 'prop-types';

// Components
import ContentAdded from '@components/students/shared/StudentList/Student/ContentAdded.jsx';

export const StudentRevisionRow = ({ course, isOpen, toggleDrawer, student, uploadsLink }) => {
  return (
    <tr onClick={toggleDrawer} className={`students ${isOpen ? 'open' : ''}`}>
      <td className="desktop-only-tc">{student.recent_revisions}</td>
      <td className="desktop-only-tc">
        <ContentAdded course={course} student={student} />
      </td>
      <td className="desktop-only-tc">
        {student.references_count}
      </td>
      <td className="desktop-only-tc">
        <Link
          to={uploadsLink}
          onClick={() => { this.setUploadFilters([{ value: student.username, label: student.username }]); }}
        >
          {student.total_uploads || 0}
        </Link>
      </td>
      <td><button className="icon icon-arrow-toggle table-expandable-indicator" /></td>
    </tr>
  );
};

StudentRevisionRow.propTypes = {
  course: PropTypes.object.isRequired,
  isOpen: PropTypes.bool.isRequired,
  student: PropTypes.shape({
    recent_revisions: PropTypes.number.isRequired,
    references_count: PropTypes.number.isRequired,
    total_uploads: PropTypes.number,
    username: PropTypes.string.isRequired
  }).isRequired,
  uploadsLink: PropTypes.string.isRequired
};

export default StudentRevisionRow;
