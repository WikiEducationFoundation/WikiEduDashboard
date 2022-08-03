import React from 'react';
import { DummyBlock } from './DummyBlock';
import SpringBlock from './SpringBlock';
import { Flipper } from 'react-flip-toolkit';

const BlockList = ({ blocks, moveBlock, week_id, ...props }) => {
  const springBlocks = blocks.map((block, i) => {
    block.order = i;
    return <SpringBlock block={block} i={i} key={block.id} {...props} />;
  });
  return (
    <Flipper flipKey={blocks.map(block => block.id).join('')} spring="stiff">
      <ul className="week__block-list list-unstyled" style={{ display: 'flex', flexDirection: 'column', gap: '15px' }}>
        {springBlocks.length ? springBlocks : <DummyBlock text={I18n.t('timeline.empty_week_drag_items')} week_id={week_id} moveBlock={moveBlock}/>}
      </ul>
    </Flipper>
  );
};

export default BlockList;
