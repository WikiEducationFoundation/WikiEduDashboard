React           = require 'react'
Reorderable     = require '../high_order/reorderable.cjsx'

OrderableBlock = React.createClass(
  displayName: 'OrderableBlock'

  propTypes:
    title: React.PropTypes.string.isRequired
    kind: React.PropTypes.string.isRequired
    disableUp: React.PropTypes.bool.isRequired
    disableDown: React.PropTypes.bool.isRequired
    canDrag: React.PropTypes.bool.isRequired
    onDrag: React.PropTypes.func.isRequired
    onMoveUp: React.PropTypes.func.isRequired
    onMoveDown: React.PropTypes.func.isRequired

  render: ->
    <div className="block block--orderable" style={{opacity: if @props.isDragging then .5 else 1}}>
      <h4 className="block-title">{@props.title}</h4>
      <p>{@props.kind}</p>
      <button onClick={@props.onMoveDown} className="button border" aria-label="Move block down" disabled={@props.disableDown}><i className="icon icon-arrow-down"/></button>
      <button onClick={@props.onMoveUp} className="button border" aria-label="Move block up" disabled={@props.disableUp}><i className="icon icon-arrow-up"/></button>
    </div>

)

module.exports = Reorderable(OrderableBlock, 'block', 'onDrag')
