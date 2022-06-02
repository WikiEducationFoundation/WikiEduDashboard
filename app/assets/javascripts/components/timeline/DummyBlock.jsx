import React from 'react';
import { useDrop } from 'react-dnd';

export const DummyBlock = ({ week_id, onMoveBlockDown, onMoveBlockUp }) => {
  const [{ isOverCurrent }, drop] = useDrop(
    () => ({
      accept: 'block',
      drop(_item, monitor) {
        const didDrop = monitor.didDrop();
        if (didDrop) {
          return;
        }
        if (_item.item.week_id <= week_id) {
          onMoveBlockDown(_item.item.id, true);
        } else {
          onMoveBlockUp(_item.item.id, true);
        }
      },
      collect: monitor => ({
        isOver: monitor.isOver(),
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
