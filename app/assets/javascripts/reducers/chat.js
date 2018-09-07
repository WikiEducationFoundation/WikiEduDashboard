import { CHAT_LOGIN_SUCCEEDED } from '../constants';

const initialState = {
  authToken: null,
};

export default function chat(state = initialState, action) {
  switch (action.type) {
    case CHAT_LOGIN_SUCCEEDED: {
      return {
        authToken: action.payload.data.auth_token,
      };
    }
    default:
      return state;
  }
}
