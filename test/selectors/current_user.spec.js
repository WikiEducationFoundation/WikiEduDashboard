import '../testHelper';
import {
  getCurrentUser, getRealCurrentUser, getCanViewAsStudent, getIsViewingAsStudent, editPermissions
} from '../../app/assets/javascripts/selectors';
import { restoreStudentView, leaveStudentView } from '../../app/assets/javascripts/actions/student_view_actions';
import { isStudentViewActive, readStoredStudentView, setStudentViewActive, storeStudentView } from '../../app/assets/javascripts/utils/student_view';
import { INSTRUCTOR_ROLE, STAFF_ROLE, STUDENT_ROLE } from '../../app/assets/javascripts/constants';

describe('current user in student view', () => {
  const buildState = ({ role = INSTRUCTOR_ROLE, admin = false, type = 'ClassroomProgramCourse', viewAsStudent = true } = {}) => ({
    currentUserFromHtml: { id: 1, admin, campaign_organizer: false },
    users: { users: [{ id: 1, username: 'Instructor', role, admin }, { id: 2, username: 'Student', role: STUDENT_ROLE }] },
    course: { type, closed: false },
    viewAsStudent
  });

  test('gives an instructor the roles of an enrolled student', () => {
    const user = getCurrentUser(buildState());
    expect(user).toMatchObject({ id: 1, username: 'Instructor', role: STUDENT_ROLE, admin: false, isStudent: true, isEnrolled: true });
    expect(user.isInstructor).toBeUndefined();
    expect(user.isAdvancedRole).toBeUndefined();
    expect(user.notEnrolled).toBeUndefined();
  });

  test('removes edit permissions', () => {
    expect(editPermissions(buildState({ viewAsStudent: false }))).toBe(true);
    expect(editPermissions(buildState())).toBe(false);
  });

  test('also drops admin roles for an admin who is an instructor of the course', () => {
    const user = getCurrentUser(buildState({ admin: true }));
    expect(user.admin).toBe(false);
    expect(user.isAdmin).toBeUndefined();
  });

  test('keeps the real roles available', () => {
    expect(getRealCurrentUser(buildState())).toMatchObject({ role: INSTRUCTOR_ROLE, isInstructor: true });
  });

  test('changes nothing while student view is off', () => {
    const state = buildState({ viewAsStudent: false });
    expect(getIsViewingAsStudent(state)).toBe(false);
    expect(getCurrentUser(state)).toMatchObject({ role: INSTRUCTOR_ROLE, isInstructor: true });
  });

  test('is only available in Wikipedia Student Program courses', () => {
    const state = buildState({ type: 'Editathon' });
    expect(getCanViewAsStudent(state)).toBe(false);
    expect(getIsViewingAsStudent(state)).toBe(false);
    expect(getCurrentUser(state)).toMatchObject({ isInstructor: true });
  });

  test('is only available to instructors', () => {
    const staffState = buildState({ role: STAFF_ROLE });
    expect(getCanViewAsStudent(staffState)).toBe(false);
    expect(getCurrentUser(staffState)).toMatchObject({ isStaff: true, isAdvancedRole: true });

    const adminState = {
      ...buildState({ admin: true }),
      users: { users: [{ id: 2, username: 'Student', role: STUDENT_ROLE }] }
    };
    expect(getCanViewAsStudent(adminState)).toBe(false);
    expect(getCurrentUser(adminState)).toMatchObject({ admin: true, isAdmin: true });
  });

  describe('restoreStudentView', () => {
    afterEach(() => {
      setStudentViewActive(false);
      storeStudentView('school/title', false);
    });

    test('turns student view back on for a course where it was left on', () => {
      storeStudentView('school/title', true);
      const dispatch = jest.fn();
      restoreStudentView('school/title')(dispatch);
      expect(isStudentViewActive()).toBe(true);
      expect(dispatch).toHaveBeenCalledWith({ type: 'ENTER_STUDENT_VIEW' });
    });

    test('turns student view off for a course where it was not left on', () => {
      setStudentViewActive(true);
      const dispatch = jest.fn();
      restoreStudentView('school/title')(dispatch);
      expect(isStudentViewActive()).toBe(false);
      expect(dispatch).toHaveBeenCalledWith({ type: 'EXIT_STUDENT_VIEW' });
    });
  });

  describe('leaveStudentView', () => {
    afterEach(() => {
      storeStudentView('school/title', false);
    });

    test('turns student view off but keeps it saved for the course', () => {
      storeStudentView('school/title', true);
      setStudentViewActive(true);
      const dispatch = jest.fn();
      leaveStudentView()(dispatch);
      expect(isStudentViewActive()).toBe(false);
      expect(dispatch).toHaveBeenCalledWith({ type: 'EXIT_STUDENT_VIEW' });
      expect(readStoredStudentView('school/title')).toBe(true);
    });
  });
});
