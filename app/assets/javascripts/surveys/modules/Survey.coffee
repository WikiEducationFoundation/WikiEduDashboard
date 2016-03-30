#--------------------------------------------------------
# Vendor Requirements
#--------------------------------------------------------

velocity_animate = require 'velocity-animate'
parsley = require 'parsleyjs'
core_js_array = require 'core-js/modules/es6.array.is-array'
rangeslider = require 'nouislider'
wNum = require 'wnumb'
throttle = require 'lodash.throttle'


#--------------------------------------------------------
# Required Internal Modules
#--------------------------------------------------------

Utils = require './SurveyUtils.coffee'


#--------------------------------------------------------
# Survey Module Misc Options
#--------------------------------------------------------

# Scroll Animation
scroll_duration = 500
scroll_easing = [0.19, 1, 0.22, 1]


chosen_options =
  disable_search_threshold: 10
  width: '75%'


#--------------------------------------------------------
# Survey Module
#--------------------------------------------------------

Survey =
  current_block: 0
  submitted: []
  survey_conditionals: {}

  
  
  