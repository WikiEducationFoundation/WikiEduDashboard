import '../../testHelper';

import React from 'react';
import ReactDOM from 'react-dom';
import ReactTestUtils from 'react-addons-test-utils';
import Block from '../../../app/assets/javascripts/components/timeline/block.jsx';

// Block.__Rewire__('TextAreaInput', React.createClass({
  // render() {
    // return <div {...this.props}></div>;
  // }
// }));

const createBlock = (opts) => {
  const noOp = () => {};
  const block = { id: 1, title: 'Bananas' };
  return ReactTestUtils.renderIntoDocument(
    <Block
      toggleFocused={noOp}
      cancelBlockEditable={noOp}
      block={block}
      key={block.id}
      editPermissions={opts.editPermissions || false }
      moveBlock={noOp}
      week_index={1}
      allTrainingModules={[]}
      saveBlockChanges={noOp}
      weekStart={noOp}
    />
  );
};

describe('Block', () => {
  const block = { id: 1, title: 'Bananas' };
  const noOp = () => {};
  describe('render', () => {
    it('renders an li', () => {
      const TestBlock = (
        <Block
          toggleFocused={noOp}
          cancelBlockEditable={noOp}
          block={block}
          key={block.id}
          edit_permissions
          moveBlock={noOp}
          week_index={1}
          all_training_modules={[]}
          saveBlockChanges={noOp}
          weekStart={noOp}
        />
      );
      // Shallow rendering. See
      // https://facebook.github.io/react/docs/test-utils.html#shallow-rendering
      const renderer = ReactTestUtils.createRenderer();
      renderer.render(TestBlock);
      const result = renderer.getRenderOutput();
      expect(result.type).to.eq('li');
    });
    describe('title', () => {
      it('Has a title', () => {
        const TestBlock = createBlock({ editPermissions: false });
        const headline = ReactTestUtils.scryRenderedDOMComponentsWithTag(TestBlock, 'h4')[0];
        const h4 = ReactDOM.findDOMNode(headline);
        const title = h4.getElementsByTagName('span')[0].textContent;
        expect(title).to.eq(block.title);
      });
    });

    describe('edit button', () => {
      describe('edit permissions', () => {
        it('shows with edit permissions', () => {
          const TestBlock = createBlock({ editPermissions: true });
          const button = ReactTestUtils.scryRenderedDOMComponentsWithTag(TestBlock, 'button')[0];
          const buttonNode = ReactDOM.findDOMNode(button);
          expect(buttonNode.textContent).to.eq('Edit');
        });
      });
      describe('no edit permissions', () => {
        it('does not show without edit permissions', () => {
          const TestBlock = createBlock({ editPermissions: false });
          const button = ReactTestUtils.scryRenderedDOMComponentsWithTag(TestBlock, 'button')[0];
          const buttonNode = ReactDOM.findDOMNode(button);
          expect(buttonNode).to.be.null();
        });
      });
    });
  });
});

Block.__ResetDependency__('TextAreaInput');
