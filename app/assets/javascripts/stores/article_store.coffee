StockStore = require './stock_store.coffee'

ArticleStore = new StockStore(
  sortKey: 'character_sum'
  descKeys:
    character_sum: true
    view_count: true
  modelKey: 'article'
)

module.exports = ArticleStore.store
