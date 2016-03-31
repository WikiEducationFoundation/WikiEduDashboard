import '../../testHelper';
import Checkbox from '../../../app/assets/javascripts/components/common/checkbox.jsx';
import React from 'react';
import ReactTestUtils from 'react-addons-test-utils';

describe('Checkbox', () => {
  const TestCheckbox = ReactTestUtils.renderIntoDocument(
    <Checkbox
      value={false}
    />
  );

  return it('renders a checkbox input', () => {
    const checkbox = ReactTestUtils.findRenderedDOMComponentWithTag(TestCheckbox, 'p');
    return expect(checkbox.querySelectorAll('input[type=checkbox]').length).to.eq(1);
  });
});
