StockStore = require './stock_store'

StudentStore = new StockStore(
  sortKey: 'wiki_id'
  sortAsc: true
  descKeys:
    character_sum_ms: true
    character_sum_us: true
  modelKey: 'student'
  defaultModel:
    wiki_id: ""
  triggers: [
    'ENROLLED_STUDENT'
  ]
)

module.exports = StudentStore.store
