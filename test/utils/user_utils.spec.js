import UserUtils from '../../app/assets/javascripts/utils/user_utils';
import { STUDENT_ROLE, INSTRUCTOR_ROLE } from '../../app/assets/javascripts/constants/user_roles';

describe('UserUtils.userRoles', () => {
  // The "learning to edit with your students" feature relies on a single user
  // holding both the student and instructor roles for a course.
  it('marks a user enrolled in both roles as student and instructor', () => {
    const currentUser = { id: 1 };
    const users = [
      { id: 1, role: STUDENT_ROLE },
      { id: 1, role: INSTRUCTOR_ROLE },
    ];

    const roles = UserUtils.userRoles(currentUser, users);

    expect(roles.isStudent).toBe(true);
    expect(roles.isInstructor).toBe(true);
    expect(roles.isEnrolled).toBe(true);
  });
});
