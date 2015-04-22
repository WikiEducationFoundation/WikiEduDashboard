McFly = require 'mcfly'
Flux = new McFly()

#######################
###      STORE      ###
#######################
_weeks = [];

fetchWeeks = (slug) ->
  $.ajax
    type: 'GET',
    url: '/courses/' + slug + '/weeks.json'
    success: (data) =>
      console.log 'Got timeline!'
      _weeks = data
      TimelineStore.emitChange()
    failure: (e) ->
      console.log 'Couldn\'t get timeline.'

TimelineStore = Flux.createStore
  getTimeline: (slug) ->
    fetchWeeks(slug) if _weeks.length == 0
    return _weeks

, (payload) ->
  switch(payload.actionType)
    when 'ADD_WEEK'
      _weeks = payload.data
      TimelineStore.emitChange()
      break
    when 'DELETE_WEEK'
      _weeks = payload.data
      TimelineStore.emitChange()
      break
  TimelineStore.emitChange()
  return true

module.exports = TimelineStore