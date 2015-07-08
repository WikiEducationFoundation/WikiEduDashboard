$ ->
  window.I18n = I18n = require 'i18n-js'
  require("./utils/course.coffee")
  require("./utils/router.cjsx")

# jQuery plugins
$.fn.extend
  toggleHeight: ->
    return @each ->
      height = '0px'
      if $(@).css('height') == undefined || $(@).css('height') == '0px'
        height = $(@).getContentHeight()
      $(@).css('height', height)

  getContentHeight: ->
    elem = $(@).clone().css(
      "height":"auto"
      "display":"block"
    ).appendTo($(@).parent())
    height = elem.css("height")
    elem.remove()
    return height

# Prototype additions
String.prototype.trunc = (length=15) ->
  if @length > length + 3
    return @substring(0, length) + '...'
  else
    return @

String.prototype.capitalize = () ->
  this.charAt(0).toUpperCase() + this.slice(1)