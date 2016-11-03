import McFly from 'mcfly';
const Flux = new McFly();

const _articles = [];

const setArticles = function (data) {
  return data.articles.map(article => _articles.push(article));
};

const storeMethods = {
  empty() {
    return _articles.length = 0;
  },
  getArticles() {
    return _articles;
  }
};

const DidYouKnowStore = Flux.createStore(storeMethods, (payload) => {
  const { data } = payload;
  switch (payload.actionType) {
    case 'RECEIVE_DYK':
      DidYouKnowStore.empty();
      setArticles(data);
      return DidYouKnowStore.emitChange();
    default:
      // no default
  }
});

export default DidYouKnowStore;
