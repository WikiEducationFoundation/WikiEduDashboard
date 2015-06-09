StockStore = require './stock_store'

# Sort state
_sortKey = 'date'
_sortAsc = true
_descKeys =
  character_sum: true
  date: true

module.exports = new StockStore(_sortKey, _sortAsc, _descKeys, 'activity', null).store
