import React from 'react';
import ReactTestUtils, { Simulate } from 'react-dom/test-utils';
import { Provider } from 'react-redux';

import '../../testHelper';
import Checkbox from '../../../app/assets/javascripts/components/common/checkbox.jsx';

describe('Checkbox', () => {
  it('renders a checkbox input', () => {
    const TestCheckbox = ReactTestUtils.renderIntoDocument(
      <Provider store={reduxStore}>
        <Checkbox
          value={false}
        />
      </Provider>
    );
    const checkbox = ReactTestUtils.findRenderedDOMComponentWithTag(TestCheckbox, 'p');
    expect(checkbox.querySelectorAll('input[type=checkbox]').length).to.eq(1);
  });

  it('sets proper input value through props', () => {
    let TestCheckbox = ReactTestUtils.renderIntoDocument(
      <Provider store={reduxStore}>
        <Checkbox
          value={true}
        />
      </Provider>
    );
    let checkbox = ReactTestUtils.findRenderedDOMComponentWithTag(TestCheckbox, 'p');
    expect(checkbox.querySelector('input[type=checkbox]').checked).to.eq(true);
    TestCheckbox = ReactTestUtils.renderIntoDocument(
      <Provider store={reduxStore}>
        <Checkbox
          value={false}
        />
      </Provider>
    );
    checkbox = ReactTestUtils.findRenderedDOMComponentWithTag(TestCheckbox, 'p');
    expect(checkbox.querySelector('input[type=checkbox]').checked).to.eq(false);
  });

  it('calls onChange when input is changed', (done) => {
    const cb = sinon.spy();
    const TestCheckbox = ReactTestUtils.renderIntoDocument(
      <Provider store={reduxStore}>
        <Checkbox
          onChange={cb}
          value={true}
        />
      </Provider>
    );
    const checkbox = ReactTestUtils.findRenderedDOMComponentWithTag(TestCheckbox, 'input');
    Simulate.change(checkbox, { target: { checked: false } });
    setImmediate(() => {
      expect(cb.called).to.eq(true);
      expect(checkbox.checked).to.eq(false);
      done();
    });
  });
});
