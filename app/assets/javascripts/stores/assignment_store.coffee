StockStore = require './stock_store.coffee'

AssignmentStore = new StockStore(
  modelKey: 'assignment'
  triggers: [
    'SAVED_USERS',
    'USER_MODIFIED'
  ]
)

module.exports = AssignmentStore.store