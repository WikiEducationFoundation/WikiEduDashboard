import React, { useState } from 'react';
import { useSpring } from '@react-spring/web';
import OrderableBlock from './orderable_block.jsx';

export default function SpringBlock({
  i,
  block,
  onBlockDrag,
  onMoveBlockUp,
  onMoveBlockDown,
  canBlockMoveDown,
  canBlockMoveUp,
}) {
  const [y, setY] = useState(i * 75);
  useSpring({
    y: i * 75,
    onChange(change) {
      setY(change.value.y);
    },
  });
  const animating = Math.round(y) !== i * 75;
  const willChange = animating ? 'top' : 'initial';
  return (
    <li
      style={{
        top: y,
        position: 'absolute',
        width: '100%',
        left: 0,
        willChange,
        marginLeft: 0,
      }}
    >
      <OrderableBlock
        block={block}
        canDrag={true}
        animating={animating}
        onDrag={onBlockDrag.bind(null, i)}
        onMoveUp={onMoveBlockUp.bind(null, block.id)}
        onMoveDown={onMoveBlockDown.bind(null, block.id)}
        disableDown={!canBlockMoveDown(block, i)}
        disableUp={!canBlockMoveUp(block, i)}
        index={i}
        title={block.title}
        kind={
          [
            I18n.t('timeline.block_in_class'),
            I18n.t('timeline.block_assignment'),
            I18n.t('timeline.block_milestone'),
            I18n.t('timeline.block_custom'),
          ][block.kind]
        }
      />
    </li>
  );
}
