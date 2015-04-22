McFly = require 'mcfly'
Flux = new McFly()


#######################
###     ACTIONS     ###
#######################
TimelineActions = Flux.createActions
  addWeek: (text) ->
    actionType: 'ADD_WEEK',
    text: text
  addBlock: (text) ->
    actionType: 'ADD_BLOCK',
    text: text