import React from 'react';
import PropTypes from 'prop-types';

// Components
import SortButton from './SortButton.jsx';
import EnrollButton from './EnrollButton.jsx';
import NewAccountButton from '@components/enroll/new_account_button.jsx';

export const Controls = (props) => {
  const {
    course, current_user, students, notify, sortSelect
  } = props;

  let requestAccountsButton;
  if (course.account_requests_enabled && course.published) {
    requestAccountsButton = <NewAccountButton key="request_accounts" course={course} passcode={course.passcode} currentUser={current_user} />;
  }

  let notifyOverdueButton;
  if (Features.wikiEd && students.length > 0 && (course.student_count - course.trained_count) > 0) {
    notifyOverdueButton = <button className="notify_overdue" onClick={notify} key="notify" />;
  }

  return (
    <div className="users-control">
      <SortButton
        current_user={current_user}
        sortSelect={sortSelect}
      />
      {
        course.published ? (
          <EnrollButton
            key="add_student"
            allowed={false}
            course={course}
            current_user={current_user}
            role={0}
            users={students}
          />
        ) : null
      }
      { requestAccountsButton }
      { notifyOverdueButton }
    </div>
  );
};

Controls.propTypes = {
  course: PropTypes.shape({
    account_requests_enabled: PropTypes.bool.isRequired,
    passcode: PropTypes.string.isRequired,
    published: PropTypes.bool.isRequired,
    student_count: PropTypes.number.isRequired,
    trained_count: PropTypes.number.isRequired,
  }).isRequired,
  current_user: PropTypes.object.isRequired,
  students: PropTypes.array.isRequired,
  notify: PropTypes.func.isRequired,
  sortSelect: PropTypes.func.isRequired
};

export default Controls;
