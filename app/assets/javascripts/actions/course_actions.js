import McFly from 'mcfly';
import API from '../utils/api.js';

const Flux = new McFly();

const CourseActions = Flux.createActions({
  deleteAllWeeks(courseId) {
    return API.deleteAllWeeks(courseId)
      .then((data) => {
        return {
          actionType: 'DELETE_ALL_WEEKS',
          data: { id: data.courseId }
        };
      })
      .catch(resp => {
        return {
          actionType: 'API_FAIL',
          data: resp
        };
      });
  },
});

export default CourseActions;
