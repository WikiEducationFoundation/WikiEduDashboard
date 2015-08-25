React               = require 'react'

Modal = React.createClass(
  componentWillMount: ->
    $('body').addClass('modal-open')
  componentWillUnmount: ->
    $('body').removeClass('modal-open')
  render: ->
    <div className="wizard active #{@props.modalClass}">
      {@props.children}
    </div>
)

module.exports = Modal
