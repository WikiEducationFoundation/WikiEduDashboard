import StockStore from './stock_store.js';

const TrainingStatusStore = new StockStore({
  sortKey: 'id',
  sortAsc: true,
  descKeys: {
    date: true,
    characters: true
  },
  modelKey: 'training_module'
});

export default TrainingStatusStore.store;
