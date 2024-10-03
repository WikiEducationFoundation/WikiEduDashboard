import API from '../utils/api.js';
import {
  RECEIVE_TIMELINE,
  SET_BLOCK_EDITABLE,
  CANCEL_BLOCK_EDITABLE,
  UPDATE_BLOCK,
  ADD_BLOCK,
  DELETE_BLOCK,
  INSERT_BLOCK,
  UPDATE_TITLE,
  RESET_TITLES,
  ADD_WEEK,
  DELETE_WEEK,
  API_FAIL,
  SAVED_TIMELINE,
  SAVE_TIMELINE_FAIL,
  RESTORE_TIMELINE,
  DELETE_ALL_WEEKS,
} from '../constants';
import logErrorMessage from '../utils/log_error_message';
import { fetchCourse } from './course_actions';
import request from '../utils/request';

const fetchTimelinePromise = async (courseSlug) => {
  const response = await request(`/courses/${courseSlug}/timeline.json`);
  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
    response.responseText = data;
    throw response;
  }
  return response.json();
};

export const fetchTimeline = courseSlug => (dispatch) => {
  return fetchTimelinePromise(courseSlug)
    .then(data => dispatch({ type: RECEIVE_TIMELINE, data }))
    .catch(data => dispatch({ type: API_FAIL, data }));
};

export const addWeek = () => ({ type: ADD_WEEK, tempId: Date.now() });

const deleteWeekPromise = (weekId) => {
  return API.deleteWeek(weekId);
};

export const deleteWeek = weekId => (dispatch) => {
  return deleteWeekPromise(weekId)
    .then(data => dispatch({
      type: DELETE_WEEK,
      weekId: data.week_id
    }))
    .catch(data => dispatch({ type: API_FAIL, data }));
};

const deleteBlockPromise = (blockId) => {
  return API.deleteBlock(blockId);
};

export const deleteBlock = blockId => (dispatch) => {
  return deleteBlockPromise(blockId)
    .then(data => dispatch({ type: DELETE_BLOCK, blockId: data.block_id }))
    .catch(data => dispatch({ type: API_FAIL, data }));
};

export const persistTimeline = (timelineData, courseSlug) => (dispatch) => {
  return API.saveTimeline(courseSlug, timelineData)
    .then(data => dispatch({ type: SAVED_TIMELINE, data }))
    .catch((data) => {
      dispatch({ type: SAVE_TIMELINE_FAIL, data, courseSlug });
      fetchCourse(courseSlug)(dispatch);
      fetchTimeline(courseSlug)(dispatch);
    });
};

export const setBlockEditable = (blockId) => {
  return { type: SET_BLOCK_EDITABLE, blockId };
};

export const cancelBlockEditable = (blockId) => {
  return { type: CANCEL_BLOCK_EDITABLE, blockId };
};

export const updateBlock = (block) => {
  return { type: UPDATE_BLOCK, block };
};

export const addBlock = (weekId) => {
  return { type: ADD_BLOCK, weekId, tempId: Date.now() };
};

export const insertBlock = (block, newWeekId, afterBlock) => {
  return { type: INSERT_BLOCK, block, newWeekId, afterBlock };
};

export const updateTitle = (weekId, title) => {
  return { type: UPDATE_TITLE, weekId, title };
};

export const resetTitles = () => {
  return { type: RESET_TITLES };
};

export const restoreTimeline = () => {
  return { type: RESTORE_TIMELINE };
};

export const deleteAllWeeks = courseId => (dispatch) => {
  return API.deleteAllWeeks(courseId)
    .then(data => dispatch({ type: DELETE_ALL_WEEKS, data }))
    .catch(data => dispatch({ type: API_FAIL, data }));
};
