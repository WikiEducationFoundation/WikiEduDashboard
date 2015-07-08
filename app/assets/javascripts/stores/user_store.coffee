StockStore = require './stock_store'

UserStore = new StockStore(
  sortKey: 'wiki_id'
  sortAsc: true
  descKeys:
    character_sum_ms: true
    character_sum_us: true
  modelKey: 'user'
  defaultModel:
    wiki_id: ""
  triggers: [
    'USER_MODIFIED'
  ],
  uniqueKeys: ['id', 'role']
)

module.exports = UserStore.store
