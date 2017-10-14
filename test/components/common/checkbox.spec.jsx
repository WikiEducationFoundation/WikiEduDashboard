import '../../testHelper';
import Checkbox from '../../../app/assets/javascripts/components/common/checkbox.jsx';
import React from 'react';
import ReactTestUtils, { Simulate } from 'react-dom/test-utils';
import sinon from 'sinon';

describe('Checkbox', () => {
  it('renders a checkbox input', () => {
    const TestCheckbox = ReactTestUtils.renderIntoDocument(
      <Checkbox
        value={false}
      />
    );
    const checkbox = ReactTestUtils.findRenderedDOMComponentWithTag(TestCheckbox, 'p');
    expect(checkbox.querySelectorAll('input[type=checkbox]').length).to.eq(1);
  });

  it('sets proper input value through props', () => {
    let TestCheckbox = ReactTestUtils.renderIntoDocument(
      <Checkbox
        value={true}
      />
    );
    let checkbox = ReactTestUtils.findRenderedDOMComponentWithTag(TestCheckbox, 'p');
    expect(checkbox.querySelector('input[type=checkbox]').checked).to.eq(true);
    TestCheckbox = ReactTestUtils.renderIntoDocument(
      <Checkbox
        value={false}
      />
    );
    checkbox = ReactTestUtils.findRenderedDOMComponentWithTag(TestCheckbox, 'p');
    expect(checkbox.querySelector('input[type=checkbox]').checked).to.eq(false);
  });

  it('calls onChange when input is changed', (done) => {
    const cb = sinon.spy();
    const TestCheckbox = ReactTestUtils.renderIntoDocument(
      <Checkbox
        onChange={cb}
        value={true}
      />
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
