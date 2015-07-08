StockStore = require './stock_store'

CohortStore = new StockStore(
  modelKey: 'cohort'
  triggers: [
    'COHORT_MODIFIED'
  ]
)

module.exports = CohortStore.store
