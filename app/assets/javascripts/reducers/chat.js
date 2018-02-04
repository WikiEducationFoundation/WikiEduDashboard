import { CHAT_LOGIN_SUCCEEDED, SHOW_CHAT_ON } from "../constants";

const initialState = {
  authToken: null,
  showChat: false
};

export default function chat(state = initialState, action) {
  switch (action.type) {
    case SHOW_CHAT_ON: {
      return {
        authToken: state.authToken,
        showChat: true
      };
    }
    case CHAT_LOGIN_SUCCEEDED: {
      return {
        authToken: action.payload.data.auth_token,
        showChat: true
      };
    }
    default:
      return state;
  }
}
