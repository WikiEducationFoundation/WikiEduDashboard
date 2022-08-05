import React from 'react';
import { useBlockDrag } from '../../hooks/useBlockDrag';

const OrderableBlock = ({
  title,
  kind,
  disableUp,
  disableDown,
  canDrag,
  onDrag,
  onMoveUp,
  onMoveDown,
  block,
  animating
}) => {
  const { ref, isDragging, handlerId } = useBlockDrag({
    block,
    canDrag,
    isAnimating: animating,
    onBlockDragOver: onDrag
  });
  const opacity = isDragging ? 0.5 : 1;

  return (
    <div className="block block--orderable" style={{ opacity }} ref={ref} data-handler-id={handlerId}>
      <h4 className="block-title">{title}</h4>
      <p>{kind}</p>
      <button onClick={onMoveDown} className="button border" aria-label={I18n.t('timeline.move_block_down')} disabled={disableDown}>
        <i className="icon icon-arrow-down" />
      </button>
      <button onClick={onMoveUp} className="button border" aria-label={I18n.t('timeline.move_block_up')} disabled={disableUp}>
        <i className="icon icon-arrow-up" />
      </button>
    </div>
  );
};
export default OrderableBlock;
