React = require 'react'

# Enables DRY and simple conditional components
# Renders items when 'show' prop is undefined

Conditional = (Component) ->
  React.createClass(
    render: ->
      if @props.show == undefined || @props.show
        <Component {...@props} />
      else
        false
  )

module.exports = Conditional
