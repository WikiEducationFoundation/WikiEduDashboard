import React, { useEffect, useState } from 'react';
import OrderableBlock from './orderable_block.jsx';

export default function SpringBlock({
  i,
  block,
  onBlockDrag,
  onMoveBlockUp,
  onMoveBlockDown,
  canBlockMoveDown,
  canBlockMoveUp,
  animationDuration
}) {
  const [animating, setAnimating] = useState(false);

  useEffect(() => {
    setAnimating(true);

    // the animation lasts for 250ms. So we need to wait for that before we set animating to false
    setTimeout(() => {
      setAnimating(false);
    }, animationDuration);
  }, [i]);

  return (
    <li>
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
