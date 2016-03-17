Survey              = require './modules/Survey.coffee'
CourseDataQuestions = require './modules/CourseDataQuestions.coffee'

$ ->
  Survey.init()
  CourseDataQuestions.init()
  