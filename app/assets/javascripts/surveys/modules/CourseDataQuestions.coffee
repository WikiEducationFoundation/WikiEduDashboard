CourseDataQuestions =
  init: ->
    @cacheSelectors()
    @listeners()

  cacheSelectors: ->
    @$course_select = $('[data-survey-course-select]')

  listeners: ->
    @$course_select.on 'change', $.proxy @, 'updateCurrentCourse'

  updateCurrentCourse: ({target}) ->
    @current_course = target.value
    console.log @current_course


module.exports = CourseDataQuestions