import '../../testHelper';

import React from 'react';
import ReactDOM from 'react-dom';
import ReactTestUtils from 'react-addons-test-utils';
import Block from '../../../app/assets/javascripts/components/timeline/block.cjsx';

describe('Block', () => {
  describe('render', () => {
    const block = { id: 1, title: 'bananas' };
    const noOp = () => {};
    const TestBlock = ReactTestUtils.renderIntoDocument(
      <Block
        toggleFocused={noOp}
        cancelBlockEditable={noOp}
        block={block}
        key={block.id}
        edit_permissions
        moveBlock={noOp}
        week_index={1}
        all_training_modules={[]}
        editable_block_ids={[1]}
        saveBlockChanges={noOp}
      />
    );

    it('Has a title', () => {
      const headline = ReactTestUtils.scryRenderedDOMComponentsWithTag(TestBlock, 'h4')[0];
      const h4 = ReactDOM.findDOMNode(headline);
      expect(h4.textContent).to.eq(block.title);
    });
  });
});

