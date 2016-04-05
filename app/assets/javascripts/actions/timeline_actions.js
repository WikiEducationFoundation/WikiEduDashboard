import McFly from 'mcfly';
const Flux = new McFly();
import API from '../utils/api.coffee';

const TimelineActions = Flux.createActions({
  persistTimeline(data, courseId) {
    return API.saveTimeline(courseId, data)
      .then(resp => ({ actionType: 'SAVED_TIMELINE', data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  }
});

export default TimelineActions;
