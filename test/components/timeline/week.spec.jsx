import '../../testHelper';

import React from 'react';
import { findDOMNode } from 'react-dom';
import sinon from 'sinon';
import TestUtils, { Simulate } from 'react-dom/test-utils';
import ShallowTestUtils from 'react-test-renderer/shallow';
import Week from '../../../app/assets/javascripts/components/timeline/week.jsx';
import BlockActions from '../../../app/assets/javascripts/actions/block_actions.js';

const noOp = () => {};
const createWeek = (opts = {}) => {
  return TestUtils.renderIntoDocument(
    <Week
      index={1}
      blocks={opts.blocks || []}
      meetings={opts.meetings || null}
      edit_permissions={opts.edit_permissions || false}
      reorderable={opts.reorderable || false}
      week={{ is_new: opts.is_new || false }}
      deleteWeek={opts.deleteWeek || noOp}
    />
  );
};

describe('Week', () => {
  describe('render', () => {
    it('renders an li', () => {
      const TestWeek = (
        <Week
          index={1}
          blocks={[]}
          week={{ is_new: false }}
        />
      );
      // Shallow rendering. See
      // https://facebook.github.io/react/docs/test-utils.html#shallow-rendering
      const renderer = ShallowTestUtils.createRenderer();
      renderer.render(TestWeek);
      const result = renderer.getRenderOutput();
      expect(result.type).to.eq('li');
    });
  });

  describe('week add/delete', () => {
    describe('week meetings and edit permissions', () => {
      it('displays', () => {
        const TestWeek = createWeek({ edit_permissions: true, meetings: '(Tue)' });
        const container = TestUtils.scryRenderedDOMComponentsWithClass(TestWeek, 'week__week-add-delete')[0];
        const containerNode = findDOMNode(container);
        expect(containerNode.innerHTML).to.contain('Add Block');
        expect(containerNode.innerHTML).to.contain('Delete Week');
      });
    });
    describe('edit permissions, but no week meetings', () => {
      it('displays', () => {
        const TestWeek = createWeek({ edit_permissions: true, meetings: '' });
        const container = TestUtils.scryRenderedDOMComponentsWithClass(TestWeek, 'week__week-add-delete')[0];
        const containerNode = findDOMNode(container);
        expect(containerNode.innerHTML).to.contain('Delete Week');
      });
    });
    describe('week meetings, but no edit permissions', () => {
      it('does not display', () => {
        const TestWeek = createWeek({ edit_permissions: false, meetings: '(Tue)' });
        const container = TestUtils.scryRenderedDOMComponentsWithClass(TestWeek, 'week__week-add-delete')[0];
        const containerNode = findDOMNode(container);
        expect(containerNode).to.be.null;
      });
    });
  });

  describe('add block button', () => {
    const permissionsOpts = { meetings: '(Tue)', edit_permissions: true };
    describe('not reorderable, not editing added block failing', () => {
      it('displays', () => {
        const opts = { reorderable: false };
        const TestWeek = createWeek(Object.assign(opts, permissionsOpts));
        const span = TestUtils.scryRenderedDOMComponentsWithClass(TestWeek, 'week__add-block')[0];
        const spanNode = findDOMNode(span);
        expect(spanNode.textContent).to.eq('Add Block');
      });
    });
    describe('reorderable, not editing added block', () => {
      it('does not display', () => {
        const opts = { reorderable: true };
        const TestWeek = createWeek(Object.assign(opts, permissionsOpts));
        const span = TestUtils.scryRenderedDOMComponentsWithClass(TestWeek, 'week__add-block')[0];
        const spanNode = findDOMNode(span);
        expect(spanNode).to.be.null;
      });
    });
    describe('click handler', () => {
      const opts = { reorderable: false };
      const TestWeek = createWeek(Object.assign(opts, permissionsOpts));
      let method;
      let action;
      beforeAll(() => {
        method = sinon.spy(TestWeek, '_scrollToAddedBlock');
        action = sinon.spy(BlockActions, 'addBlock');
      });
      afterAll(() => {
        TestWeek._scrollToAddedBlock.restore();
        BlockActions.addBlock.restore();
      });
      const span = TestUtils.scryRenderedDOMComponentsWithClass(TestWeek, 'week__add-block')[0];
      it('calls the appropriate functions', () => {
        Simulate.click(span);
        expect(method).to.have.been.calledOnce;
        expect(action).to.have.been.calledOnce;
      });
    });
  });

  describe('delete week button', () => {
    const permissionsOpts = { meetings: '(Tue)', edit_permissions: true };
    describe('not reorderable, week is not new', () => {
      it('displays', () => {
        const opts = { reorderable: false, is_new: false };
        const TestWeek = createWeek(Object.assign(opts, permissionsOpts));
        const span = TestUtils.scryRenderedDOMComponentsWithClass(TestWeek, 'week__delete-week')[0];
        const spanNode = findDOMNode(span);
        expect(spanNode.textContent).to.eq('Delete Week');
      });
    });
    describe('reorderable, week is not new', () => {
      it('does not display', () => {
        const opts = { reorderable: true, is_new: false };
        const TestWeek = createWeek(Object.assign(opts, permissionsOpts));
        const span = TestUtils.scryRenderedDOMComponentsWithClass(TestWeek, 'week__delete-week')[0];
        const spanNode = findDOMNode(span);
        expect(spanNode).to.be.null;
      });
    });
    describe('not reorderable, week is new', () => {
      it('does not display', () => {
        const opts = { reorderable: false, is_new: true };
        const TestWeek = createWeek(Object.assign(opts, permissionsOpts));
        const span = TestUtils.scryRenderedDOMComponentsWithClass(TestWeek, 'week__delete-week')[0];
        const spanNode = findDOMNode(span);
        expect(spanNode).to.be.null;
      });
    });
    describe('click handler', () => {
      const spy = sinon.spy();
      const opts = { reorderable: false, is_new: false, deleteWeek: spy };
      const TestWeek = createWeek(Object.assign(opts, permissionsOpts));
      const span = TestUtils.scryRenderedDOMComponentsWithClass(TestWeek, 'week__delete-week')[0];
      const spanNode = findDOMNode(span);
      it('calls delete week', () => {
        Simulate.click(spanNode);
        expect(spy).to.have.been.calledOnce;
      });
    });
  });

  describe('week content', () => {
    describe('week has meetings', () => {
      const TestWeek = createWeek({ meetings: '(W)', blocks: [{ id: 1 }] });
      it('shows a week ul with meetings', () => {
        const ul = TestUtils.scryRenderedDOMComponentsWithClass(TestWeek, 'week__block-list')[0];
        const ulNode = findDOMNode(ul);
        expect(ulNode.tagName.toLowerCase()).to.eq('ul');
        expect(ulNode.children[0].tagName.toLowerCase()).to.eq('li');
      });
    });
    describe('week has no meetings', () => {
      const TestWeek = createWeek();
      it('warns that week is past timeline end', () => {
        const week = findDOMNode(TestWeek);
        expect(week.innerHTML).to.contain('AFTER TIMELINE END DATE');
      });
    });
  });
});
