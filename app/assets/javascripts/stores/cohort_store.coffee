StockStore = require './stock_store.coffee'

CohortStore = new StockStore(
  modelKey: 'cohort'
)

module.exports = CohortStore.store
