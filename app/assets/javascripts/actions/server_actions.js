import McFly from 'mcfly';
import API from '../utils/api.js';
const Flux = new McFly();

const ServerActions = Flux.createActions({
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
