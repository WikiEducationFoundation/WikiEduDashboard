McFly       = require 'mcfly'
Flux        = new McFly()

UIActions = Flux.createActions
  open: (key) ->
    { actionType: 'OPEN_KEY', data: {
      key: key
    }}

module.exports = UIActions