import { ENTER_STUDENT_VIEW, EXIT_STUDENT_VIEW } from '../constants';
import { fetchCourse } from './course_actions';
import { fetchUsers } from './user_actions';
import { readStoredStudentView, setStudentViewActive, storeStudentView } from '../utils/student_view';

// The course and users data differ in student view, so they're refetched
// whenever it's switched on or off.
const refetchViewerDependentData = (courseSlug, dispatch) => Promise.all([
  dispatch(fetchCourse(courseSlug)),
  dispatch(fetchUsers(courseSlug))
]);

// Called before the course page's first fetch, so a reload in student view
// requests student data from the start. Whether the user may use student view
// isn't known until the course and users load; the selectors check that.
// Student view is saved per course, so it's switched off for a course where it
// wasn't left on.
export const restoreStudentView = courseSlug => (dispatch) => {
  const stored = readStoredStudentView(courseSlug);
  setStudentViewActive(stored);
  dispatch({ type: stored ? ENTER_STUDENT_VIEW : EXIT_STUDENT_VIEW });
};

// Called when the course page unmounts, so pages reached from it without a
// reload don't block writes. The course's saved choice is kept.
export const leaveStudentView = () => (dispatch) => {
  setStudentViewActive(false);
  dispatch({ type: EXIT_STUDENT_VIEW });
};

export const enterStudentView = courseSlug => (dispatch) => {
  storeStudentView(courseSlug, true);
  setStudentViewActive(true);
  dispatch({ type: ENTER_STUDENT_VIEW });
  return refetchViewerDependentData(courseSlug, dispatch);
};

export const exitStudentView = courseSlug => (dispatch) => {
  storeStudentView(courseSlug, false);
  setStudentViewActive(false);
  dispatch({ type: EXIT_STUDENT_VIEW });
  return refetchViewerDependentData(courseSlug, dispatch);
};
