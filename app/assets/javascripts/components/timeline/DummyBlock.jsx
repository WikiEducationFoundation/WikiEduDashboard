import React from 'react';
import { useDrop } from 'react-dnd';

export const DummyBlock = ({ week_id, moveBlock, text }) => {
  const [{ isOverCurrent }, drop] = useDrop(
    () => ({
      accept: 'block',
      drop(item, monitor) {
        const didDrop = monitor.didDrop();
        if (didDrop) {
          return;
        }
        // item is the block. 0 is the target index in the week.
        moveBlock(item, week_id, 0);
      },
      collect: monitor => ({
        isOverCurrent: monitor.isOver({ shallow: true }),
      }),
    }),
    [],
  );
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
        height: '75px',
        fontSize: '1rem',
        display: 'grid',
        placeItems: 'center'
      }}
    >
      {text}
    </div>
  );
};
