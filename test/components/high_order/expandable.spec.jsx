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
    expect(dom.querySelector('.wrapper')).to.exist;

    ReactTestUtils.Simulate.click(dom.querySelector('.component'));
  });
});
