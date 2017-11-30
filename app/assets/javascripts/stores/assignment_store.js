import StockStore from './stock_store.js';

const AssignmentStore = new StockStore({
  sortKey: 'article_title',
  sortAsc: true,
  modelKey: 'assignment',
  triggers: [
    'SAVED_USERS',
    'USER_MODIFIED'
  ]
});

export default AssignmentStore.store;
