React = require 'react'

# Enables DRY and simple conditional components

Conditional = (Component) ->
  React.createClass(
    render: ->
      show = this.props.show == undefined || this.props.show
      return <Component {...this.props} /> if show
      return false
  )

module.exports = Conditional