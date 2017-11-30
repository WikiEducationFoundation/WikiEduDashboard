import StockStore from './stock_store.js';

const UploadStore = new StockStore({
  sortKey: 'file_name',
  sortAsc: true,
  descKeys: {
    usage_count: true,
    date: true,
    uploader: true
  },
  modelKey: 'upload'
});

export default UploadStore.store;
