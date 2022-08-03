import React, { useRef } from 'react';
import { useDrag, useDrop } from 'react-dnd';

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
  const ref = useRef(null);

  // this makes the block draggable
  const [{ isDragging }, drag] = useDrag({
    type: 'block',
    item: () => {
      return block;
    },
    collect: monitor => ({
      isDragging: monitor.isDragging(),
    }),
  });

  // this makes the block a drop target for other blocks
  const [{ handlerId }, drop] = useDrop({
    accept: 'block',
    collect(monitor) {
      return {
        handlerId: monitor.getHandlerId(),
      };
    },
    hover(item, monitor) {
      const adjacent = Math.abs(item.order - block.order) <= 1;

      // animating && adjacent prevents the block from jumping when it's animating
      if (!ref.current || !canDrag || (animating && adjacent)) {
        return;
      }
      // this is the index of the block that is being dragged
      const dragIndex = monitor.getItem().order;

      // this is the index of the block that is being hovered over
      const hoverIndex = block.order;

      // if the index and week of both the block being dragged and hovered over are the same,
      // then the blocks are same. So we don't need to do anything.
      if (dragIndex === hoverIndex && monitor.getItem().week_id === block.week_id) {
        return;
      }

      // this gets the coordinates of the block being hovered over
      const hoverBoundingRect = ref.current?.getBoundingClientRect();

      // when block is being dragged from top to bottom
      // we provide a padding of 30px. If the dragged block's y coordinate is more than 30px away from the top of the hovered block,
      // then we don't do anything.
      if (dragIndex < hoverIndex && monitor.getSourceClientOffset().y + 30 < hoverBoundingRect.top) {
        return;
      }

      // when block is being dragged from bottom to top
      // we provide a padding of 30px. If the dragged block's y coordinate is more than 30px away from the bottom of the hovered block,
      // then we don't do anything.
      if (dragIndex > hoverIndex && monitor.getSourceClientOffset().y - 30 > hoverBoundingRect.bottom) {
        return;
      }

      // otherwise, we move the blocks
      // item is the dragged block. block is the block being hovered on(ie the current block)
      onDrag(item, block);
      item.order = hoverIndex;
    },
  });
  drag(drop(ref));
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
