React             = require 'react'
RDnD              = require 'react-dnd'
DragSource        = RDnD.DragSource
DropTarget        = RDnD.DropTarget

# This component is used for components which function both as draggable
# items and also as their own "drop targets". As of 8/12/2015 the Block
# component is the only implementation of this concept.

# An overview of React-DnD, explaining the concepts summarized below
# http://gaearon.github.io/react-dnd/docs-overview.html

# param {React Component} Component - The component to be given reorderable properties
# param {String} Type - The kind of data model represented by the Component
# param {String} MoveFunction - The name of the function (in the props) to run when an item is moved
module.exports = (Component, Type, MoveFunction) ->

  # These functions allow us to modify how the
  # draggable component reacts to drag-and-drop events
  dragSourceSpec =
    beginDrag: (props) ->
      props[Type]
    isDragging: (props, monitor) ->
      props[Type].id == monitor.getItem().id
    canDrag: (props, monitor) ->
      if props.canDrag?
        props.canDrag
      else
        true

  # Returns props to inject into the draggable component
  sourceConnect = (connect, monitor) ->
    connectDragSource: connect.dragSource()
    isDragging: monitor.isDragging()

  # These functions allow us to modify how the
  # drag target reacts to drag-and-drop events
  dragTargetSpec =
    hover: (props, monitor) ->
      item = monitor.getItem()
      props[MoveFunction](item.id, props[Type].id)

  # Returns props to inject into the drag target component
  targetConnect =  (connect, monitor) ->
    connectDropTarget: connect.dropTarget()

  # Simple wrapper for rendering the passed Component as draggable or not
  Reorderable = React.createClass(
    displayName: 'Reorderable'
    render: ->
      if @props.editable
        _.flow(@props.connectDragSource, @props.connectDropTarget)(
          <div>
            <Component {...@props} />
          </div>
        )
      else
        <div>
          <Component {...@props} />
        </div>
  )

  # The lodash `flow` function is essentially a chain, passing the return
  # value of each function to the next. Note here that DragSource() and
  # DragTarget() both return functions which are then used in the flow.
  _.flow(
    DragSource(Type, dragSourceSpec, sourceConnect),
    DropTarget(Type, dragTargetSpec, targetConnect)
  )(Reorderable)
