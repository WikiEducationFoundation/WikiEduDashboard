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
export const restoreStudentView = courseSlug => (dispatch) => {
  if (!readStoredStudentView(courseSlug)) { return; }
  setStudentViewActive(true);
  dispatch({ type: ENTER_STUDENT_VIEW });
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
