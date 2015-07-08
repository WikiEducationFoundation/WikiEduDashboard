StockStore = require './stock_store'

TagStore = new StockStore(
  modelKey: 'tag'
)

module.exports = TagStore.store