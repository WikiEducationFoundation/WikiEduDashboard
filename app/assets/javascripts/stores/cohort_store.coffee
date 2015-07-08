StockStore = require './stock_store'

CohortStore = new StockStore(
  modelKey: 'cohort'
)

module.exports = CohortStore.store
