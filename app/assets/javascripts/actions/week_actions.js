import McFly from 'mcfly';
const Flux = new McFly();
import API from '../utils/api.coffee';

const WeekActions = Flux.createActions({
  addWeek() {
    return { actionType: 'ADD_WEEK' };
  },

  updateWeek(week) {
    return {
      actionType: 'UPDATE_WEEK',
      data: {
        week
      }
    };
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

  setWeekEditable(weekId) {
    return {
      actionType: 'SET_WEEK_EDITABLE',
      data: {
        week_id: weekId
      }
    };
  }
});

export default WeekActions;
