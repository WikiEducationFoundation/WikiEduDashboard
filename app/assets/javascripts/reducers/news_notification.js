import { pull } from 'lodash-es';
import { ADD_NEWS_NOTIFICATION, REMOVE_NEWS_NOTIFICATION } from '../constants';

const initialState = [];

export default function newsNotifications(state = initialState, action) {
  switch (action.type) {
    case ADD_NEWS_NOTIFICATION: {
      const newState = [...state];
      newState.push(action.notification);
      return newState;
    }
    case REMOVE_NEWS_NOTIFICATION: {
      const newState = [...state];
      pull(newState, action.notification);
      return newState;
    }
    default:
      return state;
  }
}
