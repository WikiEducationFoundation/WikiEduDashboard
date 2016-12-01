import McFly from 'mcfly';
const Flux = new McFly();
import API from '../utils/api.js';

const TimelineActions = Flux.createActions({
  persistTimeline(data, courseId) {
    return API.saveTimeline(courseId, data)
      .then(resp => ({ actionType: 'SAVED_TIMELINE', data: resp }))
      .catch(resp => ({ actionType: 'SAVE_TIMELINE_FAIL', data: resp }));
  }
});

export default TimelineActions;
