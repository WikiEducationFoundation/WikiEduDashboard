import StockStore from './stock_store.js';

const UserStore = new StockStore({
  sortKey: 'username',
  sortAsc: true,
  descKeys: {
    character_sum_ms: true,
    character_sum_us: true
  },
  modelKey: 'user',
  defaultModel: {
    username: ''
  },
  uniqueKeys: ['id', 'role']
});

export default UserStore.store;
