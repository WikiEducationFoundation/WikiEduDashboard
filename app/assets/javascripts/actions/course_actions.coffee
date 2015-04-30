McFly       = require 'mcfly'
Flux        = new McFly()

CourseActions = Flux.createActions
  receiveCourse: (data) ->
    { actionType: 'RECEIVE_COURSE', data: {
      course: data
    }}

module.exports = CourseActions