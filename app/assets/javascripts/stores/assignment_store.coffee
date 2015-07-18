StockStore = require './stock_store'

AssignmentStore = new StockStore(
  modelKey: 'assignment'
  triggers: [
    'SAVED_USERS',
    'USER_MODIFIED'
  ]
)

module.exports = AssignmentStore.store