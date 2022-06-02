import React from 'react';
import { useDrop } from 'react-dnd';

export const DummyBlock = ({ week_id, moveBlock }) => {
  const [{ isOverCurrent }, drop] = useDrop(
    () => ({
      accept: 'block',
      drop(item, monitor) {
        const didDrop = monitor.didDrop();
        if (didDrop) {
          return;
        }
        // item.item is the block. 0 is the target index in the week.
        moveBlock(item.item, week_id, 0);
      },
      collect: monitor => ({
        isOverCurrent: monitor.isOver({ shallow: true }),
      }),
    }),
    [],
  );
  const text = 'Empty week. Drag items here ';
  let backgroundColor = '#919090';
  if (isOverCurrent) {
    backgroundColor = '#676EB4';
  }
  return (
    <div
      ref={drop}
      style={{
        border: '1px solid #dedcdc',
        color: 'white',
        backgroundColor,
        height: '100%',
        fontSize: '1rem',
        display: 'grid',
        placeItems: 'center'
      }}
    >
      {text}
    </div>
  );
};
