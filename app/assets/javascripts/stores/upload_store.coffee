StockStore = require './stock_store'

# Sort state
_sortKey = 'file_name'
_sortAsc = true
_descKeys =
  usages: true
  date: true

module.exports = new StockStore(_sortKey, _sortAsc, _descKeys, 'uploads', null).store
