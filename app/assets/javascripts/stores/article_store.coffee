StockStore = require './stock_store'

# Sort state
_sortKey = 'title'
_sortAsc = true
_descKeys =
  character_sum: true
  view_count: true

module.exports = new StockStore(_sortKey, _sortAsc, _descKeys, 'articles', null).store

