import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { DragSource, DropTarget } from 'react-dnd';
import { findDOMNode } from 'react-dom';
import _ from 'lodash';

// This component is used for components which function both as draggable
// items and also as their own "drop targets". As of 8/12/2015 the Block
// component is the only implementation of this concept.

// An overview of React-DnD, explaining the concepts summarized below
// https://react-dnd.github.io/react-dnd/docs-overview.html

// param {React Component} Component - The component to be given reorderable properties
// param {String} Type - The kind of data model represented by the Component
// param {String} MoveFunction - The name of the function (in the props) to run when an item is moved
export default function (Component, Type, MoveFunction) {
  // These functions allow us to modify how the
  // draggable component reacts to drag-and-drop events
  const dragSourceSpec = {
    beginDrag(props) {
      document.body.classList.add('unselectable');
      return {
        props,
        item: props[Type],
        originalIndex: props.index
      };
    },
    isDragging(props, monitor) {
      return props[Type].id === monitor.getItem().item.id;
    },
    canDrag(props) {
      if (props.canDrag !== null) {
        return props.canDrag;
      }
      return true;
    },
    endDrag() {
      return document.body.classList.remove('unselectable');
    }
  };

  // Returns props to inject into the draggable component
  const sourceConnect = (connect, monitor) =>
    ({
      connectDragSource: connect.dragSource(),
      connectDragPreview: connect.dragPreview(),
      isDragging: monitor.isDragging()
    })
  ;

  // These functions allow us to modify how the
  // drag target reacts to drag-and-drop events
  const dragTargetSpec = {
    hover(props, monitor) {
      const { item } = monitor.getItem();
      const adjacent = Math.abs(item.order - props[Type].order) <= 1;
      if ((item.id === props[Type].id || props.animating) && adjacent) { return; }
      return props[MoveFunction](item, props[Type], monitor.getItem().originalIndex);
    }
  };

  // Returns props to inject into the drag target component
  const targetConnect = (connect) => ({ connectDropTarget: connect.dropTarget() });

  // Simple wrapper for rendering the passed Component as draggable or not
  const Reorderable = createReactClass({
    displayName: 'Reorderable',

    propTypes: {
      canDrag: PropTypes.bool,
      connectDropTarget: PropTypes.func,
      connectDragSource: PropTypes.func,
      connectDragPreview: PropTypes.func
    },

    render() {
      if (this.props.canDrag) {
        return (
          <Component
            {...this.props} ref={(instance) => {
              this.props.connectDropTarget(findDOMNode(instance));
              this.props.connectDragSource(findDOMNode(instance), { dropEffect: 'move' });
              this.props.connectDragPreview(findDOMNode(instance));
            }}
          />
        );
      }
      return <Component {...this.props} />;
    }
  });

  // The lodash `flow` function is essentially a chain, passing the return
  // value of each function to the next. Note here that DragSource() and
  // DragTarget() both return functions which are then used in the flow.
  return _.flow(
    DragSource(Type, dragSourceSpec, sourceConnect),
    DropTarget(Type, dragTargetSpec, targetConnect)
  )(Reorderable);
}
