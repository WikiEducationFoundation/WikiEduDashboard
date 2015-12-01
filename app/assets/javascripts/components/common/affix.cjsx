React = require 'react'

Affix = React.createClass(
  getDefaultProps: ->
    offset: 0

  getInitialState: ->
    affix: false

  componentDidMount: ->
    window.addEventListener 'scroll', @_handleScroll

  componentWillMount: ->
    window.removeEventListener 'scroll', @_handleScroll

  _handleScroll: ->
    affix = @state.affix
    offset = @props.offset
    scrollTop = document.documentElement.scrollTop || document.body.scrollTop

    @setState affix: true if !affix && scrollTop >= offset
    @setState affix: false if affix && scrollTop < offset

  render: ->
    affix = if @state.affix is true then 'affix' else ''
    className = @props.className
    className += " #{affix}"

    <div className={className}>
      {@props.children}
    </div>
)

module.exports = Affix
