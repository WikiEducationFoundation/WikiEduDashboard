McFly       = require 'mcfly'
Flux        = new McFly()

UIActions = Flux.createActions
  open: (key) ->
    { actionType: 'OPEN_KEY', data: {
      key: key
    }}
  sort: (kind, key) ->
    { actionType: 'SORT_' + kind.toUpperCase(), data: {
      key: key
    }}

module.exports = UIActions