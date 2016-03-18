#--------------------------------------------------------
# Vendor Requirements
#--------------------------------------------------------

_where = require 'lodash.where'
_reject = require 'lodash.reject'
_map = require 'lodash.map'
require 'core-js/modules/es6.object.keys'


Utils = require './SurveyUtils.coffee'
Survey = require './Survey.coffee'

#--------------------------------------------------------
# CourseDataQuestions Module
#--------------------------------------------------------

CourseDataQuestions =
  init: ->
    @cacheSelectors()
    return unless @$course_select.length
    @gatherCourseQuestionTypes()
    @listeners()

  cacheSelectors: ->
    @$course_select = $('[data-survey-course-select]')
    @$course_questions = $('[data-course-question-type]')

  listeners: ->
    @$course_select.on 'change', $.proxy @, 'updateCurrentCourse'
    $('[data-next-survey-block]:first').on 'click', $.proxy @, 'populateCourseQuestionFields'

  updateCurrentCourse: ({target}) ->
    @current_course_slug = target.value

  gatherCourseQuestionTypes: ->
    types = []
    @$course_questions_by_type = {}
    @$course_questions.each (i, question) =>
      type = $(question).data 'course-question-type'
      if types.indexOf(type) is -1
        types.push type
      @$course_questions_by_type[type] = $("[data-course-question-type='#{type}']")
    @course_data_types = types
  
  getAPIEndpoints: ->
    @course_data = {}
    endpoints_to_fetch = []
    @course_data_types.map (type) =>
      endpoint = switch(type)
        when 'students', 'wikiedu staff' then 'users'
        when 'articles' then 'articles'
        else null
      return if endpoint is null
      if endpoints_to_fetch.indexOf(endpoint) is -1
        endpoints_to_fetch.push endpoint
      @course_data[type] = {}
      @course_data[type].endpoint = endpoint
    return endpoints_to_fetch

  fetchCourseData: ->
    api_endpoints = @getAPIEndpoints()
    defer = $.Deferred()
    api_endpoints.map (endpoint, i) =>
      $.getJSON("/courses/#{@current_course_slug}/#{endpoint}").then ({course}) =>
        console.log course
        _where(@course_data, {endpoint: endpoint}).map (type) ->
          type.data = course
        defer.resolve() if i is api_endpoints.length - 1
    return defer.promise()

  populateCourseQuestionFields: ->
    return if @$course_select.val() is ""
    $.when @fetchCourseData()
    .then =>
      Object.keys(@$course_questions_by_type).map (type) =>
        $question = $(@$course_questions_by_type[type])
        $select = $($question.next('[data-course-question-select]'))
        @addCourseQuestionListeners $question, $select
        @populateSelectByType $select, type

  populateSelectByType: ($select, type) ->
    course_data = @course_data[type].data[@course_data[type].endpoint]
    course_data_options = switch type
      when 'students'
        _reject course_data, (u) -> return u.role is 4 or u.role is 1
      when 'wikiedu staff'
        _where course_data, {role: 4}
      else
        course_data

    optionKey = switch type
      when 'students', 'wikiedu staff' then 'username'
      when 'articles' then 'title'

    @removeQuestion($select, type) if course_data_options.length is 0
    
    $select.append "<option value=''></option>"
    course_data_options.map (item) ->
      if item[optionKey]?
        $select.append "<option value='#{item.id}'>#{item[optionKey]}</option>"
        $('[data-chosen-select]').trigger "chosen:updated"
    $select.removeClass 'loading'
    $select.parent().find('.spinner').hide()

  addCourseQuestionListeners: ($question, $select) ->
    $select.on 'change', ({target}) ->
      $question.val target.value

  removeQuestion: ($select, type) ->
    $select.parents('.block').addClass('hidden').remove()
    Survey.indexBlocks()
    console.log "#{type} question was removed because there was no data found."




module.exports = CourseDataQuestions