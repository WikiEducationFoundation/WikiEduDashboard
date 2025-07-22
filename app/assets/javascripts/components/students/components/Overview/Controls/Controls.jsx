import React from 'react';
import PropTypes from 'prop-types';

// Components
import SortButton from '@components/students/shared/SortButton.jsx';
import EnrollButton from '../../../../common/enroll_button.jsx';
import NewAccountButton from '@components/enroll/new_account_button.jsx';

export const Controls = (props) => {
  const {
    course, current_user, students, notify, showOverviewFilters, sortSelect
  } = props;

  let requestAccountsButton;
  if (course.account_requests_enabled && course.published) {
    requestAccountsButton = <NewAccountButton key="request_accounts" course={course} passcode={course.passcode} currentUser={current_user} />;
  }

  // This corresponds to CoursesController#notify_untrained
  let notifyOverdueButton;
  if (Features.wikiEd && students.length > 0 && (course.student_count - course.trained_count) > 0) {
    notifyOverdueButton = <button className="notify_overdue" title={I18n.t('wiki_edits.notify_overdue.button_label')} onClick={notify} key="notify" />;
  }

  return (
    <div className="users-control">
      <SortButton
        current_user={current_user}
        showOverviewFilters={showOverviewFilters}
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
      {requestAccountsButton}
      {notifyOverdueButton}
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
