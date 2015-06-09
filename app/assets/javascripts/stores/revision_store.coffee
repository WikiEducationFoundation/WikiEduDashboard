StockStore = require './stock_store'

# Sort state
_sortKey = 'date'
_sortAsc = false
_descKeys =
  date: true
  characters: true
  rating_num: true

module.exports = new StockStore(_sortKey, _sortAsc, _descKeys, 'revisions', null).store
