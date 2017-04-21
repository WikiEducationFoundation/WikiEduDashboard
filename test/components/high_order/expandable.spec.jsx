import '../../testHelper';
import Expandable from '../../../app/assets/javascripts/components/high_order/expandable.jsx';
import UIStore from '../../../app/assets/javascripts/stores/ui_store.js';
import UIActions from '../../../app/assets/javascripts/actions/ui_actions.js';
import React from 'react';
import ReactTestUtils, { Simulate } from 'react-addons-test-utils';
import sinon from 'sinon';

describe.only('Expandable', () => {
  const MyComponent = React.createClass({
    render() {
      return (
        <div className="component">
          <h1>A title</h1>
        </div>
      );
    }
  });

  const MyExpandableComponent = Expandable(MyComponent);

  it('renders', () => {
    const dom = ReactTestUtils.renderIntoDocument(
      <div className="wrapper">
        <MyExpandableComponent />
      </div>
    );

    expect(dom.querySelector('.component')).to.exist;

    // FIXME: This selector is not found!
    // We need something outside the component to click on and collapse it.
    expect(dom.querySelector('.wrapper')).to.exist;

    // TODO: Expand the component
    ReactTestUtils.Simulate.click(dom.querySelector('.component'));

    // TODO: Asset that the component is expanded.

    // TODO: Collapse the component clicking outside.
    ReactTestUtils.Simulate.click(dom.querySelector('.wrapper'));

    // TODO: Assert that the component is collapsed.
  });
});
