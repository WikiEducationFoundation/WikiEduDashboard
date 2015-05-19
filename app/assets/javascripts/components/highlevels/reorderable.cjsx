React             = require 'react/addons'
RDnD              = require 'react-dnd'
HTML5Backend      = require 'react-dnd/modules/backends/HTML5'
DDContext         = RDnD.DragDropContext
DragSource        = RDnD.DragSource
DropTarget        = RDnD.DropTarget

module.exports = (Component, Type, MoveFunction) ->
  dragSource =
    beginDrag: (props) ->
      props[Type]
  sourceConnect = (connect, monitor) ->
    connectDragSource: connect.dragSource()
    isDragging: monitor.isDragging()

  dragTarget =
    hover: (props, monitor) ->
      item = monitor.getItem()
      props[MoveFunction](item.id, props[Type].id)
  targetConnect =  (connect, monitor) ->
    connectDropTarget: connect.dropTarget()

  Reorderable = React.createClass(
    displayName: 'Reorderable'
    render: ->
      _.flow(@props.connectDragSource, @props.connectDropTarget)(
        <Component {...@props} />
      )
  )

  _.flow(
    DragSource(Type, dragSource, sourceConnect),
    DropTarget(Type, dragTarget, targetConnect)
  )(Reorderable)
