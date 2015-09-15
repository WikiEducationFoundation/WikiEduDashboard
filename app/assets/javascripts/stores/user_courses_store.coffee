McFly       = require 'mcfly'
Flux        = new McFly()

_userCourses = []

setUserCourses = (data) ->
  _.forEach data.courses, (course) -> _userCourses.push(course)
  UserCoursesStore.emitChange()

UserCoursesStore = Flux.createStore
  getUserCourses: ->
    return _userCourses
, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'RECEIVE_USER_COURSES'
      setUserCourses data
      break

module.exports = UserCoursesStore
