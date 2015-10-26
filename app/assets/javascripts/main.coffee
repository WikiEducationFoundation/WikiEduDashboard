$ ->
  window.I18n = I18n = require 'i18n-js'
  require("./utils/course.coffee")
  require("./utils/router.cjsx")
  require("events").EventEmitter.defaultMaxListeners = 30

require './main-utils.coffee'
