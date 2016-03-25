SurveyAdmin = require './modules/SurveyAdmin.coffee'
SurveyAssignmentAdmin = require './modules/SurveyAssignmentAdmin.coffee'

$ ->
  SurveyAdmin.init()
  SurveyAssignmentAdmin.init()