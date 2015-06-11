StockStore = require './stock_store'

# Sort state
_sortKey = 'date'
_sortAsc = false
_descKeys =
  date: true
  characters: true

module.exports = new StockStore(_sortKey, _sortAsc, _descKeys, 'revision', null).store
