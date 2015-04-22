McFly = require 'mcfly'
Flux = new McFly()

#######################
###      STORE      ###
#######################
_weeks = [];

addWeek = (course_id) ->#, week) ->
  $.ajax
    type: 'POST',
    url: '/courses/' + course_id + '/weeks'
    data: week
    success: ->
      console.log 'Week added!'
    failure: (e) ->
      console.log 'Week not added! ' + e

addBlock = (course_id) ->#, week_id, block) ->
  $.ajax
    type: 'POST',
    url: '/courses/' + course_id + '/weeks/' + week_id + '/blocks'
    data: block
    success: ->
      console.log 'Block added!'
    failure: (e) ->
      console.log 'Block not added! ' + e

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
      addWeek(payload.text)
      break
    when 'ADD_BLOCK'
      addBlock(payload.text)
      break
  TimelineStore.emitChange()
  return true

module.exports = TimelineStore