StockStore = require './stock_store'

CohortStore = new StockStore(
  modelKey: 'cohort'
  triggers: [
    'LIST_COURSE'
  ]
)

module.exports = CohortStore.store
