import React from 'react';
import SortButton from '@components/students/components/Controls/SortButton.jsx';
import EnrollButton from '@components/students/enroll_button.jsx';
import NewAccountButton from '@components/enroll/new_account_button.jsx';

export const Controls = (props) => {
  const {
    course, current_user, editAssignments, students, notify, sortSelect, toggleAssignmentEditingMode
  } = props;
  let assignArticlesButton;
  if (students.length > 0) {
    const assignLabel = editAssignments ? I18n.t('users.assign_articles_done') : I18n.t('users.assign_articles');
    assignArticlesButton = <button className="dark button" onClick={toggleAssignmentEditingMode} key="assign_articles">{assignLabel}</button>;
  }

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
      { assignArticlesButton }
      {
        course.published ? (
          <EnrollButton
            {...props}
            allowed={false}
            key="add_student"
            role={0}
            users={students}
          />
        ) : null
      }
      { requestAccountsButton }
      { notifyOverdueButton }
      <SortButton
        current_user={current_user}
        sortSelect={sortSelect}
      />
    </div>
  );
};

export default Controls;
