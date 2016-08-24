import StockStore from './stock_store.coffee';

const TagStore = new StockStore(
  { modelKey: 'tag' }
);

export default TagStore.store;
