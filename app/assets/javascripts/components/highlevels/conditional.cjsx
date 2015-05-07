React = require 'react'

# Enables DRY and simple conditional components
# Renders items when 'show' prop is undefined

Conditional = (Component) ->
  React.createClass(
    render: ->
      if this.props.show == undefined || this.props.show
        <Component {...this.props} />
      else
        false
  )

module.exports = Conditional
