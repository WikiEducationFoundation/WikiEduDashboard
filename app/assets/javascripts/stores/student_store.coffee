StockStore = require './stock_store'

# Sort state
_sortKey = 'wiki_id'
_sortAsc = true
_descKeys =
  character_sum_ms: true
  character_sum_us: true

new_student = {
  id: Date.now(), # could THEORETICALLY collide but highly unlikely
  is_new: true, # remove ids from objects with is_new when persisting
  wiki_id: ""
}

module.exports = new StockStore(_sortKey, _sortAsc, _descKeys, 'student', new_student, ['ENROLLED_STUDENT']).store

# module.exports = new StockStore({
#   sortKey: 'wiki_id'
#   sortAsc: true
#   descKeys:
#     character_sum_ms: true
#     character_sum_us: true
#   modelKey: 'student'
#   defaultModel: {
#     wiki_id: ""
#   }
#   triggers: [
#     'ENROLLED_STUDENT'
#   ]
# }).store
