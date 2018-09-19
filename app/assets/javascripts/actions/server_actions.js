import McFly from 'mcfly';
import _ from 'lodash';
import API from '../utils/api.js';
const Flux = new McFly();

const ServerActions = Flux.createActions({
  fetchAllTrainingModules() {
    return API.fetchAllTrainingModules()
      .then(resp => ({ actionType: 'RECEIVE_ALL_TRAINING_MODULES', data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  },

  fetchTrainingModule(opts = {}) {
    return API.fetchTrainingModule(opts)
      .then(resp => ({ actionType: 'RECEIVE_TRAINING_MODULE', data: _.extend(resp, { slide: opts.current_slide_id }) }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  },

  setSlideCompleted(opts) {
    return API.setSlideCompleted(opts)
      .then(resp => ({ actionType: 'SLIDE_COMPLETED', data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  },

  checkCourse(key, courseId) {
    return API.fetch(courseId, 'check')
      .then(resp => {
        const message = resp.course_exists ? I18n.t('courses.creator.already_exists') : null;
        return {
          actionType: 'CHECK_SERVER',
          data: {
            key,
            message
          }
        };
      })
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  },
});

export default ServerActions;
