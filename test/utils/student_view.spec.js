import '../testHelper';
import request from '../../app/assets/javascripts/utils/request';
import {
  isBlockedInStudentView, readStoredStudentView, setStudentViewActive, storeStudentView,
  studentViewQuery
} from '../../app/assets/javascripts/utils/student_view';

describe('student view', () => {
  afterEach(() => {
    setStudentViewActive(false);
  });

  describe('isBlockedInStudentView', () => {
    test('blocks nothing while student view is off', () => {
      expect(isBlockedInStudentView('DELETE', '/courses/school/title/user.json')).toBe(false);
    });

    test('allows reads', () => {
      setStudentViewActive(true);
      expect(isBlockedInStudentView('GET', '/courses/school/title/course.json')).toBe(false);
    });

    test('allows the assignment writes an instructor can make for themselves', () => {
      setStudentViewActive(true);
      expect(isBlockedInStudentView('POST', '/assignments.json?user_id=1&role=0')).toBe(false);
      expect(isBlockedInStudentView('DELETE', '/assignments/12?user_id=1')).toBe(false);
      expect(isBlockedInStudentView('PUT', '/assignments/12/claim')).toBe(false);
      expect(isBlockedInStudentView('PATCH', '/assignments/12/status.json')).toBe(false);
      expect(isBlockedInStudentView('PATCH', '/assignments/12/update_sandbox_url')).toBe(false);
    });

    test('blocks other writes', () => {
      setStudentViewActive(true);
      expect(isBlockedInStudentView('POST', '/assignments/12/assignment_suggestions')).toBe(true);
      expect(isBlockedInStudentView('DELETE', '/courses/school/title/user.json')).toBe(true);
      expect(isBlockedInStudentView('POST', '/assignments/assign_reviewers_randomly?course_slug=a')).toBe(true);
    });

    test('treats lowercase methods the same', () => {
      setStudentViewActive(true);
      expect(isBlockedInStudentView('delete', '/courses/school/title/user.json')).toBe(true);
    });

    test('allows changing the interface language', () => {
      setStudentViewActive(true);
      expect(isBlockedInStudentView('POST', '/update_locale/es')).toBe(false);
    });

    test('does not block requests to other sites', () => {
      setStudentViewActive(true);
      expect(isBlockedInStudentView('POST', 'https://api.wikimedia.org/service/lw/inference/v1/models')).toBe(false);
    });
  });

  describe('studentViewQuery', () => {
    test('adds nothing while student view is off', () => {
      expect(studentViewQuery('course')).toBe('');
    });

    test('asks for student data from the course and users endpoints', () => {
      setStudentViewActive(true);
      expect(studentViewQuery('course')).toBe('?view_as=student');
      expect(studentViewQuery('users')).toBe('?view_as=student');
      expect(studentViewQuery('timeline')).toBe('');
    });
  });

  describe('stored state', () => {
    test('is remembered per course', () => {
      storeStudentView('school/one', true);
      expect(readStoredStudentView('school/one')).toBe(true);
      expect(readStoredStudentView('school/two')).toBe(false);
      storeStudentView('school/one', false);
      expect(readStoredStudentView('school/one')).toBe(false);
    });
  });

  describe('request', () => {
    beforeEach(() => {
      global.fetch = jest.fn(() => Promise.resolve({ ok: true, status: 200, json: () => Promise.resolve({}) }));
    });

    test('answers a blocked write with a 403 carrying a message, without sending it', async () => {
      setStudentViewActive(true);
      const response = await request('/courses/school/title/user.json', { method: 'DELETE' });
      expect(global.fetch).not.toHaveBeenCalled();
      expect(response.ok).toBe(false);
      expect(response.status).toBe(403);
      const body = await response.json();
      expect(body.message).toBe(I18n.t('courses.student_view_action_blocked'));
    });

    test('sends an allowed write', async () => {
      setStudentViewActive(true);
      await request('/assignments/12/claim', { method: 'PUT' });
      expect(global.fetch).toHaveBeenCalledTimes(1);
    });
  });
});
