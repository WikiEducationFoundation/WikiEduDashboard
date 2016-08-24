import StockStore from './stock_store.coffee';

const CohortStore = new StockStore(
  { modelKey: 'cohort' }
);

export default CohortStore.store;
