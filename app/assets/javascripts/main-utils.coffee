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
String.prototype.trunc = (truncation=15) ->
  if @length > truncation + 3
    return @substring(0, truncation) + '…'
  else
    return @.valueOf()

String.prototype.capitalize = () ->
  this.charAt(0).toUpperCase() + this.slice(1)
