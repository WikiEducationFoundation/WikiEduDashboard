import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import Reorderable from '../high_order/reorderable.jsx';

const OrderableBlock = createReactClass({
  displayName: 'OrderableBlock',

  propTypes: {
    title: PropTypes.string,
    kind: PropTypes.string,
    disableUp: PropTypes.bool.isRequired,
    disableDown: PropTypes.bool.isRequired,
    canDrag: PropTypes.bool.isRequired,
    onDrag: PropTypes.func.isRequired,
    onMoveUp: PropTypes.func.isRequired,
    onMoveDown: PropTypes.func.isRequired,
    isDragging: PropTypes.bool.isRequired
  },

  render() {
    const opacity = this.props.isDragging ? 0.5 : 1;

    return (
      <div className="block block--orderable" style={{ opacity }}>
        <h4 className="block-title">{this.props.title}</h4>
        <p>{this.props.kind}</p>
        <button onClick={this.props.onMoveDown} className="button border" aria-label={I18n.t('timeline.move_block_down')} disabled={this.props.disableDown}>
          <i className="icon icon-arrow-down" />
        </button>
        <button onClick={this.props.onMoveUp} className="button border" aria-label={I18n.t('timeline.move_block_up')} disabled={this.props.disableUp}>
          <i className="icon icon-arrow-up" />
        </button>
      </div>
    );
  }
});

// Reorderable relies on a `ref` to this component, so it can't be converted
// to a stateless functional component.
export default Reorderable(OrderableBlock, 'block', 'onDrag');
