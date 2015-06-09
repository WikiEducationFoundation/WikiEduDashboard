StockStore = require './stock_store'

# Sort state
_sortKey = 'file_name'
_sortAsc = true
_descKeys =
  usage_count: true
  date: true
  uploader: true

module.exports = new StockStore(_sortKey, _sortAsc, _descKeys, 'uploads', null).store
