McFly = require 'mcfly'
Flux  = new McFly()

_module = {}

setModule = (trainingModule) ->
  _module = trainingModule
  TrainingStore.emitChange()


TrainingStore = Flux.createStore
  getTrainingModule: ->
    return _module
, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'RECEIVE_TRAINING_MODULES'
      setModule data.training_module
      break

module.exports = TrainingStore
