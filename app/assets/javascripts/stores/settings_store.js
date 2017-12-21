import StockStore from './stock_store.js';

const settingsStore = new StockStore({
  adminUsers: [],
  fetchingUsers: false,
  submittingNewAdmin: false,
  RevokingAdmin: false
});

export default settingsStore.store;
