import React, { useState } from 'react';
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
  const [isHoverArrowDown, setIsHoverArrowDown] = useState(false);
  const [isHoverArrowUp, setIsHoverArrowUp] = useState(false);
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
      <button onClick={onMoveDown} onMouseEnter={() => setIsHoverArrowDown(true)} onMouseLeave={() => setIsHoverArrowDown(false)} className="button border" aria-label={I18n.t('timeline.move_block_down')} disabled={disableDown}>
        <i className={`icon ${isHoverArrowDown ? 'icon-arrow-down_white' : 'icon-arrow-down'}`} />
      </button>
      <button onClick={onMoveUp} onMouseEnter={() => setIsHoverArrowUp(true)} onMouseLeave={() => setIsHoverArrowUp(false)} className="button border" aria-label={I18n.t('timeline.move_block_up')} disabled={disableUp}>
        <i className={`icon ${isHoverArrowUp ? 'icon-arrow-up_white' : 'icon-arrow-up'}`} />
      </button>
    </div>
  );
};
export default OrderableBlock;
