$ ->
  require("./utils/localization.coffee")
  require("./utils/course.coffee")
  require("./utils/router.cjsx")

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

String.prototype.trunc = (length=15) ->
  if @length > length + 3
    return @substring(0, length) + '...'
  else
    return @