import McFly from 'mcfly';
import API from '../utils/api.js';
import { RECEIVE_TIMELINE, ADD_WEEK, DELETE_WEEK, API_FAIL } from '../constants';
import logErrorMessage from '../utils/log_error_message';

const Flux = new McFly();
const TimelineActions = Flux.createActions({
  persistTimeline(data, courseId) {
    return API.saveTimeline(courseId, data)
      .then(resp => ({ actionType: 'SAVED_TIMELINE', data: resp }))
      .catch(resp => ({ actionType: 'SAVE_TIMELINE_FAIL', data: resp, courseId }));
  }
});

export default TimelineActions;

const fetchTimelinePromise = courseSlug => {
  return new Promise((res, rej) =>
    $.ajax({
      type: 'GET',
      url: `/courses/${courseSlug}/timeline.json`,
      success(data) {
        return res(data);
      }
    })
    .fail((obj) => {
      logErrorMessage(obj);
      return rej(obj);
    })
  );
};

export const fetchTimeline = courseSlug => dispatch => {
  return fetchTimelinePromise(courseSlug)
    .then(data => dispatch({ type: RECEIVE_TIMELINE, data }))
    .catch(data => dispatch({ type: API_FAIL, data }));
};

export const addWeek = () => ({ type: ADD_WEEK, tempId: Date.now() });

const deleteWeekPromise = weekId => {
  return API.deleteWeek(weekId);
};

export const deleteWeek = weekId => dispatch => {
  return deleteWeekPromise(weekId)
    .then(data => dispatch({
      type: DELETE_WEEK,
      weekId: data.week_id
    }))
    .catch(data => dispatch({ type: API_FAIL, data }));
};
