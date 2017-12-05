import StockStore from './stock_store.js';

const ArticleStore = new StockStore({
  sortKey: 'character_sum',
  descKeys: {
    character_sum: true,
    view_count: true
  },
  modelKey: 'article'
});

export default ArticleStore.store;
