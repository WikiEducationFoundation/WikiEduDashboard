import '../../testHelper';

import React from 'react';
import { findDOMNode } from 'react-dom';
import TestUtils from 'react-dom/test-utils';
import ShallowTestUtils from 'react-test-renderer/shallow';
import Block from '../../../app/assets/javascripts/components/timeline/block.jsx';

Block.__Rewire__(
  'TextAreaInput',
  () => <div />
);

const createBlock = (opts) => {
  const noOp = () => {};
  const block = { id: 1, title: 'Bananas' };
  return TestUtils.renderIntoDocument(
    <Block
      toggleFocused={noOp}
      cancelBlockEditable={noOp}
      block={block}
      key={block.id}
      editPermissions={opts.editPermissions || false}
      moveBlock={noOp}
      week_index={1}
      allTrainingModules={[]}
      training_modules={opts.training_modules || []}
      saveBlockChanges={noOp}
      editableBlockIds={opts.editableBlockIds || []}
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
          editPermissions
          moveBlock={noOp}
          week_index={1}
          all_training_modules={[]}
          saveBlockChanges={noOp}
        />
      );
      // Shallow rendering. See
      // https://facebook.github.io/react/docs/test-utils.html#shallow-rendering
      const renderer = ShallowTestUtils.createRenderer();
      renderer.render(TestBlock);
      const result = renderer.getRenderOutput();
      expect(result.type).to.eq('li');
    });
    describe('title', () => {
      it('Has a title', () => {
        const TestBlock = createBlock({ editPermissions: false });
        const headline = TestUtils.scryRenderedDOMComponentsWithTag(TestBlock, 'h4')[0];
        const h4 = findDOMNode(headline);
        const title = h4.getElementsByTagName('span')[0].textContent;
        expect(title).to.eq(block.title);
      });
    });

    describe('edit button', () => {
      describe('edit permissions', () => {
        it('shows with edit permissions', () => {
          const TestBlock = createBlock({ editPermissions: true });
          const button = TestUtils.scryRenderedDOMComponentsWithTag(TestBlock, 'button')[0];
          const buttonNode = findDOMNode(button);
          expect(buttonNode.textContent).to.eq('Edit');
        });
      });
      describe('no edit permissions', () => {
        it('does not show without edit permissions', () => {
          const TestBlock = createBlock({ editPermissions: false });
          const button = TestUtils.scryRenderedDOMComponentsWithTag(TestBlock, 'button')[0];
          const buttonNode = findDOMNode(button);
          expect(buttonNode).to.be.null;
        });
      });
    });

    describe('delete button', () => {
      describe('edit permissions', () => {
        describe('edit permissions, but editable block ids do not contain this block', () => {
          it("doesn't show button", () => {
            const TestBlock = createBlock({
              editPermissions: true,
              editableBlockIds: []
            });
            const button = TestUtils.scryRenderedDOMComponentsWithClass(TestBlock, 'danger')[0];
            const buttonNode = findDOMNode(button);
            expect(buttonNode).to.be.null;
          });
        });
        describe('edit permissions, editable block ids do contain this block', () => {
          it('shows button', () => {
            const TestBlock = createBlock({
              editPermissions: true,
              editableBlockIds: [block.id]
            });
            const button = TestUtils.scryRenderedDOMComponentsWithClass(TestBlock, 'danger')[0];
            const buttonNode = findDOMNode(button);
            expect(buttonNode.textContent).to.eq('Delete Block');
          });
        });
      });
      describe('no edit permissions', () => {
        it('does not show without edit permissions', () => {
          const TestBlock = createBlock({ editPermissions: false });
          const button = TestUtils.scryRenderedDOMComponentsWithTag(TestBlock, 'button')[0];
          const buttonNode = findDOMNode(button);
          expect(buttonNode).to.be.null;
        });
      });
    });

    describe('training modules', () => {
      describe('block has training modules, edit permissions present', () => {
        const TestBlock = createBlock({
          editableBlockIds: [1],
          block: { id: 1, training_modules: [{ name: 'apples' }] }
        });
        it('shows modules', () => {
          const blkHTML = findDOMNode(TestBlock).innerHTML;
          expect(blkHTML.match('block__training-modules').index).not.to.be.null;
        });
      });
      describe('block has no training modules, but edit permissions present', () => {
        const TestBlock = createBlock({
          editableBlockIds: [],
          block: { id: 1, training_modules: [] }
        });
        it('does not show modules', () => {
          const modules = TestUtils.scryRenderedDOMComponentsWithClass(TestBlock, 'block__training-modules')[0];
          const modulesNode = findDOMNode(modules);
          expect(modulesNode).to.be.null;
        });
      });
      describe('block has no training modules, no edit permissions', () => {
        const TestBlock = createBlock({
          editableBlockIds: [],
          block: { id: 1, training_modules: [] }
        });
        it('does not show modules', () => {
          const modules = TestUtils.scryRenderedDOMComponentsWithClass(TestBlock, 'block__training-modules')[0];
          const modulesNode = findDOMNode(modules);
          expect(modulesNode).to.be.null;
        });
      });
    });
  });
});
