StockStore = require './stock_store.coffee'

TagStore = new StockStore(
  modelKey: 'tag'
)

module.exports = TagStore.store