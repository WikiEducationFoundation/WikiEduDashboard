import StockStore from './stock_store.coffee';

const AssignmentStore = new StockStore({
  modelKey: 'assignment',
  triggers: [
    'SAVED_USERS',
    'USER_MODIFIED'
  ]
}
);

export default AssignmentStore.store;
