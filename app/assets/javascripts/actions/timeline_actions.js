import McFly from 'mcfly';
import API from '../utils/api.js';
const Flux = new McFly();

const TimelineActions = Flux.createActions({
  persistTimeline(data, courseId) {
    return API.saveTimeline(courseId, data)
      .then(resp => ({ actionType: 'SAVED_TIMELINE', data: resp }))
      .catch(resp => ({ actionType: 'SAVE_TIMELINE_FAIL', data: resp, courseId }));
  }
});

export default TimelineActions;
