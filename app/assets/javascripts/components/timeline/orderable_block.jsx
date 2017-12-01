import React from 'react';
import PropTypes from 'prop-types';
import Reorderable from '../high_order/reorderable.jsx';

const OrderableBlock = ({
  title,
  kind,
  isDragging,
  disableUp,
  disableDown,
  onMoveUp,
  onMoveDown
}) => {
  const opacity = isDragging ? 0.5 : 1;

  return (
    <div className="block block--orderable" style={{ opacity }}>
      <h4 className="block-title">{title}</h4>
      <p>{kind}</p>
      <button
        onClick={onMoveDown}
        className="button border"
        aria-label={I18n.t('timeline.move_block_up')}
        disabled={disableDown}
      >
        <i className="icon icon-arrow-down" />
      </button>
      <button
        onClick={onMoveUp}
        className="button border"
        aria-label={I18n.t('timeline.move_block_down')}
        disabled={disableUp}
      >
        <i className="icon icon-arrow-up" />
      </button>
    </div>);
};

OrderableBlock.propTypes = {
  title: PropTypes.string,
  kind: PropTypes.string.isRequired,
  disableUp: PropTypes.bool.isRequired,
  disableDown: PropTypes.bool.isRequired,
  onMoveUp: PropTypes.func.isRequired,
  onMoveDown: PropTypes.func.isRequired,
  isDragging: PropTypes.bool.isRequired
};

export default Reorderable(
  OrderableBlock,
  'block',
  'onDrag'
);
