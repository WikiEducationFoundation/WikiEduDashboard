import React, { useEffect, useRef } from 'react';
import autoAnimate from '@formkit/auto-animate';
import { DummyBlock } from './DummyBlock';
import SpringBlock from './SpringBlock';

const ANIMATION_DURATION = 250;
const BlockList = ({ blocks, moveBlock, week_id, ...props }) => {
  const springBlocks = blocks.map((block, i) => <SpringBlock block={block} i={i} key={block.id} animationDuration={ANIMATION_DURATION} {...props} />);
  const parent = useRef();

  useEffect(() => {
    if (parent.current) {
      autoAnimate(parent.current, {
        duration: ANIMATION_DURATION,
      });
    }
  }, [parent]);


  return (
    <ul className="week__block-list list-unstyled" ref={parent} style={{ display: 'flex', flexDirection: 'column', gap: '15px' }}>
      {springBlocks.length ? springBlocks : <DummyBlock text={I18n.t('timeline.empty_week_drag_items')} week_id={week_id} moveBlock={moveBlock}/>}
    </ul>
  );
};

export default BlockList;
