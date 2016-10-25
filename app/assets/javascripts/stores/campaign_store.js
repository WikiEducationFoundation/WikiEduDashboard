import StockStore from './stock_store.coffee';

const CampaignStore = new StockStore(
  { modelKey: 'campaign' }
);

export default CampaignStore.store;
