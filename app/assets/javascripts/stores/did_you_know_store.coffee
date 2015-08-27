McFly       = require 'mcfly'
Flux        = new McFly()
ServerActions = '../actions/server_actions'


_articles = []

setArticles = (data) ->
  data.articles.map (article) -> _articles.push(article)
  DidYouKnowStore.emitChange()

DidYouKnowStore = Flux.createStore
  getArticles: ->
    return _articles
, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'RECEIVE_DYK'
      setArticles data
      break


module.exports = DidYouKnowStore
