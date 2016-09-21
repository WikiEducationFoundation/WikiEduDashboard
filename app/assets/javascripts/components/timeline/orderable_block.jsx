import React from 'react';
import Reorderable from '../high_order/reorderable.cjsx';

const OrderableBlock = React.createClass({
  displayName: 'OrderableBlock',

  propTypes: {
    title: React.PropTypes.string,
    kind: React.PropTypes.string.isRequired,
    disableUp: React.PropTypes.bool.isRequired,
    disableDown: React.PropTypes.bool.isRequired,
    canDrag: React.PropTypes.bool.isRequired,
    onDrag: React.PropTypes.func.isRequired,
    onMoveUp: React.PropTypes.func.isRequired,
    onMoveDown: React.PropTypes.func.isRequired,
    isDragging: React.PropTypes.bool.isRequired
  },

  render() {
    const opacity = this.props.isDragging ? 0.5 : 1;

    return (
      <div className="block block--orderable" style={{ opacity }}>
        <h4 className="block-title">{this.props.title}</h4>
        <p>{this.props.kind}</p>
        <button onClick={this.props.onMoveDown} className="button border" aria-label={I18n.t('timeline.move_block_up')} disabled={this.props.disableDown}>
          <i className="icon icon-arrow-down" />
        </button>
        <button onClick={this.props.onMoveUp} className="button border" aria-label={I18n.t('timeline.move_block_down')} disabled={this.props.disableUp}>
          <i className="icon icon-arrow-up" />
        </button>
      </div>);
  }
}

);

export default Reorderable(OrderableBlock, 'block', 'onDrag');
