import StockStore from './stock_store.coffee';

const ArticleDetailsStore = new StockStore({
  modelKey: 'article_details'
}
);

export default ArticleDetailsStore.store;
