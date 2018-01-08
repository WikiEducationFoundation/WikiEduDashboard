import McFly from 'mcfly';
import API from '../utils/api.js';
const Flux = new McFly();

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
});

export default WeekActions;
