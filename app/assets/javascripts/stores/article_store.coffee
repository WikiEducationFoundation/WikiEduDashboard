StockStore = require './stock_store'

ArticleStore = new StockStore(
  sortKey: 'title'
  sortAsc: true
  descKeys:
    character_sum: true
    view_count: true
  modelKey: 'article'
)

module.exports = ArticleStore.store
