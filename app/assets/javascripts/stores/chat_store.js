import McFly from 'mcfly';
const Flux = new McFly();

let _authToken = null;

const setAuthToken = function (data) {
  return _authToken = data.auth_token;
};

const storeMethods = {
  getAuthToken() {
    return _authToken;
  }
};

const ChatStore = Flux.createStore(storeMethods, (payload) => {
  const { data } = payload;
  switch (payload.actionType) {
    case 'CHAT_LOGIN_SUCCEEDED':
      setAuthToken(data);
      return ChatStore.emitChange();
    default:
      // no default
  }
});

export default ChatStore;
