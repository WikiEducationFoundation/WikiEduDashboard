StockStore = require './stock_store.coffee'

UserStore = new StockStore(
  sortKey: 'username'
  sortAsc: true
  descKeys:
    character_sum_ms: true
    character_sum_us: true
  modelKey: 'user'
  defaultModel:
    username: ""
  uniqueKeys: ['id', 'role']
)

module.exports = UserStore.store
