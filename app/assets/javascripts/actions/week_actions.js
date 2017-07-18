import McFly from 'mcfly';
const Flux = new McFly();
import API from '../utils/api.js';

const WeekActions = Flux.createActions({
  addWeek() {
    return { actionType: 'ADD_WEEK' };
  },
  deleteWeek(weekId) {
    return API.deleteWeek(weekId)
      .then(data => ({
        actionType: 'DELETE_WEEK',
        data: {
          week_id: data.week_id
        }
      }))
      .catch(data => ({ actionType: 'API_FAIL', data }));
  },
  deleteAllWeeks(weeks) {
    return API.deleteAllWeeks(weeks)
      .then(data => ({
        actionType: 'DELETE_ALL_WEEKS',
        data: {
          weeks: data.weeks
        }
      }))
      .catch(data => ({ actionType: 'API_FAIL', data }));
  },
});

export default WeekActions;
