import McFly from 'mcfly';
const Flux = new McFly();

let _articleDetails = {};

const setDetails = function (data) {
  return _articleDetails = data.article_details;
};

const storeMethods = {
  getArticleDetails() {
    return _articleDetails;
  }
};

const ArticleDetailsStore = Flux.createStore(storeMethods, (payload) => {
  const { data } = payload;
  switch (payload.actionType) {
    case 'RECEIVE_ARTICLE_DETAILS':
      setDetails(data);
      return ArticleDetailsStore.emitChange();
    default:
      // no default
  }
});

ArticleDetailsStore.clear = function () {
  _articleDetails = {};
  return ArticleDetailsStore.emitChange();
};

ArticleDetailsStore.setMaxListeners(0);

export default ArticleDetailsStore;
