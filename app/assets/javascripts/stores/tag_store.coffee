StockStore = require './stock_store'

TagStore = new StockStore(
  modelKey: 'tag'
  triggers: [
    'TAG_COURSE'
  ]
)

module.exports = TagStore.store