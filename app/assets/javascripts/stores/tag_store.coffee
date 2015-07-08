StockStore = require './stock_store'

TagStore = new StockStore(
  modelKey: 'tag'
  triggers: [
    'TAG_MODIFIED'
  ]
)

module.exports = TagStore.store