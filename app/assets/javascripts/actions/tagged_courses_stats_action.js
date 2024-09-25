import { GET_TAGGED_COURSES_STATS, API_FAIL } from '../constants';
import logErrorMessage from '../utils/log_error_message';
import request from '../utils/request';

const getTaggedCoursesStats = async (slug) => {
  try {
    const res = await request(`/tagged_courses/${slug}.json`);
    if (res.ok && res.status === 200) {
      return await res.json();
    }
    throw res;
  } catch (error) {
    logErrorMessage(error);
  }
};

export const fetchTaggedCourseStats = slug => async (dispatch) => {
  try {
    const tagged_course_stats = await getTaggedCoursesStats(slug);
    dispatch({
      type: GET_TAGGED_COURSES_STATS,
      tagged_course_stats
    });
  } catch (error) {
    dispatch({ type: API_FAIL, data: error });
  }
};
