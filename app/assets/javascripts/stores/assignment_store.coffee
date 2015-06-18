StockStore = require './stock_store'

AssignmentStore = new StockStore(
  modelKey: 'assignment'
  triggers: [
    'SAVED_STUDENTS',
    'ENROLLED_STUDENT'
  ]
)

module.exports = AssignmentStore.store