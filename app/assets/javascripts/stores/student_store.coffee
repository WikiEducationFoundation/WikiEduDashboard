StockStore = require './stock_store'

# Sort state
_sortKey = 'wiki_id'
_sortAsc = true
_descKeys =
  character_sum_ms: true
  character_sum_us: true

addStudent = ->
  setStudent {
    id: Date.now(), # could THEORETICALLY collide but highly unlikely
    is_new: true, # remove ids from objects with is_new when persisting
    wiki_id: ""
  }

module.exports = new StockStore(_sortKey, _sortAsc, _descKeys, 'students', addStudent).store
