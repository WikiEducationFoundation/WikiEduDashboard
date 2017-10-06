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
});

export default WeekActions;
