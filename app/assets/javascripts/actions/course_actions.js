import {
  ADD_NOTIFICATION,
  API_FAIL,
  UPDATE_COURSE,
  RECEIVE_COURSE,
  RECEIVE_COURSE_UPDATE,
  PERSISTED_COURSE,
  DISMISS_SURVEY_NOTIFICATION,
  TOGGLE_EDITING_SYLLABUS,
  START_SYLLABUS_UPLOAD,
  SYLLABUS_UPLOAD_SUCCESS,
  LINKED_TO_SALESFORCE,
  COURSE_SLUG_EXISTS,
  RECEIVE_COURSE_SEARCH_RESULTS,
  SORT_COURSE_SEARCH_RESULTS,
  FETCH_COURSE_SEARCH_RESULTS,
  RECEIVE_ACTIVE_COURSES,
  SORT_ACTIVE_COURSES,
  RECEIVE_CAMPAIGN_ACTIVE_COURSES,
  RECEIVE_WIKI_COURSES,
  SORT_WIKI_COURSES,
} from "../constants/index";
import API from "../utils/api.js";
import CourseUtils from "../utils/course_utils";
import request from "../utils/request";
import { toWikiDomain } from "../utils/wiki_utils";

export const fetchCourse = (courseSlug) => (dispatch) => {
  return API.fetch(courseSlug, "course")
    .then((data) => dispatch({ type: RECEIVE_COURSE, data }))
    .catch((data) => dispatch({ type: API_FAIL, data }));
};

export const refetchCourse = (courseSlug) => (dispatch) => {
  return (
    API.fetch(courseSlug, "course")
      .then((data) => dispatch({ type: RECEIVE_COURSE_UPDATE, data }))
      // These periodic refetches will error if network connection is lost.
      // Missing a refetch is benign. Using `silent`, we don't clutter the
      // interface with error notifications.
      .catch((data) => dispatch({ type: API_FAIL, data, silent: true }))
  );
};

export const updateCourse = (course) => ({ type: UPDATE_COURSE, course });

export const resetCourse = () => (dispatch, getState) => {
  const persistedCourse = getState().persistedCourse;
  dispatch({ type: UPDATE_COURSE, course: { ...persistedCourse } });
};

export const nameHasChanged = () => (_dispatch, getState) => {
  const { course, persistedCourse } = getState();
  if (course.title !== persistedCourse.title) {
    return true;
  }
  if (course.term !== persistedCourse.term) {
    return true;
  }
  if (course.school !== persistedCourse.school) {
    return true;
  }
  return false;
};

const redirectCourse = (newSlug) => {
  if (!newSlug) {
    return;
  }
  window.location = `/courses/${newSlug}`;
};

const persistAndRedirect = (course, courseSlug, newSlug, dispatch) => {
  return API.saveCourse({ course }, courseSlug)
    .then((resp) => dispatch({ type: PERSISTED_COURSE, data: resp }))
    .then(() => redirectCourse(newSlug))
    .catch((error) => {
      // Improved error handling
      let errorMessage = "An error occurred."; // Default message
      if (error && error.data && error.data.error) {
        // Check for the error structure
        errorMessage = error.data.error;
      } else if (error && error.message) {
        errorMessage = error.message;
      } else if (error && error.data) {
        errorMessage = error.data;
      }
      dispatch({ type: API_FAIL, data: errorMessage }); // Dispatch the extracted message
    });
};

export const persistCourse =
  (courseSlug = null, redirect = false) =>
  (dispatch, getState) => {
    let course = getState().course;

    let newSlug;
    if (redirect) {
      course = CourseUtils.cleanupCourseSlugComponents(course);
      newSlug = CourseUtils.generateTempId(course);
      course.slug = newSlug;
    }
    return persistAndRedirect(course, courseSlug, newSlug, dispatch);
  };

export const updateClonedCourse =
  (course, courseSlug, newSlug) => (dispatch) => {
    // Ensure course name is unique
    return API.fetch(newSlug, "check")
      .then((resp) => {
        // Course name is all good, so save it.
        if (!resp.course_exists) {
          return persistAndRedirect(course, courseSlug, newSlug, dispatch);
        }
        // Course name is taken, so show a warning.
        const message =
          "This course already exists. Consider changing the name, school, or term to make it unique.";
        return dispatch({ type: COURSE_SLUG_EXISTS, message });
      })
      .catch((data) => ({ type: API_FAIL, data }));
  };

const needsUpdatePromise = (courseSlug) => {
  return API.fetch(courseSlug, "needs_update")
    .then((data) => {
      return data;
    })
    .catch((err) => {
      return err;
    });
};

const needsUpdateNotification = (response) => {
  return {
    message: response.result,
    closable: true,
    type: "success",
  };
};

export function needsUpdate(courseSlug) {
  return function (dispatch) {
    return needsUpdatePromise(courseSlug)
      .then((resp) =>
        dispatch({
          type: ADD_NOTIFICATION,
          notification: needsUpdateNotification(resp),
        })
      )
      .catch((data) => dispatch({ type: API_FAIL, data }));
  };
}

export const dismissNotification = (id) => (dispatch) => {
  return API.dismissNotification(id)
    .then(() => dispatch({ type: DISMISS_SURVEY_NOTIFICATION, id }))
    .catch((data) => dispatch({ type: API_FAIL, data }));
};

export const toggleEditingSyllabus = () => {
  return { type: TOGGLE_EDITING_SYLLABUS };
};

export const uploadSyllabus = (payload) => (dispatch) => {
  dispatch({ type: START_SYLLABUS_UPLOAD });
  return API.uploadSyllabus(payload)
    .then((data) =>
      dispatch({ type: SYLLABUS_UPLOAD_SUCCESS, syllabus: data.url })
    )
    .catch((data) => dispatch({ type: API_FAIL, data }));
};

export const linkToSalesforce = (courseId, salesforceId) => (dispatch) => {
  return API.linkToSalesforce(courseId, salesforceId)
    .then((data) => dispatch({ type: LINKED_TO_SALESFORCE, data }))
    .catch((data) => dispatch({ type: API_FAIL, data }));
};

// Actions not handled by redux, except for failures

export const updateSalesforceRecord = (courseId) => (dispatch) => {
  return API.updateSalesforceRecord(courseId)
    .then((data) => dispatch({ type: "UPDATED_SALESFORCE_RECORD", data }))
    .catch((data) => dispatch({ type: API_FAIL, data }));
};

export const deleteCourse = (courseSlug) => (dispatch) => {
  return API.deleteCourse(courseSlug)
    .then((data) => dispatch({ type: "DELETED_COURSE", data }))
    .catch((data) => dispatch({ type: API_FAIL, data }));
};

export const removeAndDeleteCourse =
  (courseSlug, campaignTitle, campaignId, campaignSlug) => (dispatch) => {
    return API.removeAndDeleteCourse(
      courseSlug,
      campaignTitle,
      campaignId,
      campaignSlug
    )
      .then((data) => dispatch({ type: "DELETED_COURSE", data }))
      .catch((data) => dispatch({ type: API_FAIL, data }));
  };

export const notifyOverdue = (courseSlug) => (dispatch) => {
  return API.notifyOverdue(courseSlug)
    .then((data) => dispatch({ type: "NOTIFIED_OVERDUE", data }))
    .catch((data) => dispatch({ type: API_FAIL, data }));
};

export const greetStudents = (courseId) => (dispatch) => {
  return API.greetStudents(courseId)
    .then((data) => dispatch({ type: "GREETED_STUDENTS", data }))
    .catch((data) => ({ type: API_FAIL, data }));
};

export const searchPrograms = (searchQuery) => async (dispatch) => {
  dispatch({ type: FETCH_COURSE_SEARCH_RESULTS });
  const response = await request(`/courses/search.json?search=${searchQuery}`);
  if (!response.ok) {
    const data = await response.text();
    return dispatch({ type: API_FAIL, data });
  }
  const data = await response.json();
  return dispatch({ type: RECEIVE_COURSE_SEARCH_RESULTS, data });
};

export const sortCourseSearchResults = (key) => ({
  type: SORT_COURSE_SEARCH_RESULTS,
  key,
});

// this fetches the active courses of a particular campaign(which currently is just the default campaign)
export const fetchActiveCampaignCourses =
  (campaign_slug) => async (dispatch) => {
    const response = await request(
      `/campaigns/${campaign_slug}/active_courses.json`
    );
    if (!response.ok) {
      const data = await response.text();
      return dispatch({ type: API_FAIL, data });
    }
    const data = await response.json();
    return dispatch({ type: RECEIVE_CAMPAIGN_ACTIVE_COURSES, data });
  };

export const sortActiveCourses = (key) => ({ type: SORT_ACTIVE_COURSES, key });

// this fetches the active courses across all campaigns
export const fetchActiveCourses = () => async (dispatch) => {
  const response = await request("/active_courses.json");
  if (!response.ok) {
    const data = await response.text();
    return dispatch({ type: API_FAIL, data });
  }
  const data = await response.json();
  return dispatch({ type: RECEIVE_ACTIVE_COURSES, data });
};

export const fetchCoursesFromWiki = (wiki) => async (dispatch) => {
  const wiki_url = toWikiDomain(wiki);
  const response = await request(`/courses_by_wiki/${wiki_url}.json`);
  if (!response.ok) {
    const data = await response.text();
    return dispatch({ type: API_FAIL, data });
  }
  const data = await response.json();
  return dispatch({ type: RECEIVE_WIKI_COURSES, data });
};

export const sortWikiCourses = (key) => ({ type: SORT_WIKI_COURSES, key });
