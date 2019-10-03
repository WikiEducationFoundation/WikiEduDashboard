import React from 'react';
import { mount } from 'enzyme';
import { Provider } from 'react-redux';

import '../../testHelper';
import Checkbox from '../../../app/assets/javascripts/components/common/checkbox.jsx';

describe('Checkbox', () => {
  it('renders a checkbox input', () => {
    const TestCheckbox = mount(
      <Provider store={reduxStore}>
        <Checkbox
          value={false}
        />
      </Provider>
    );
    const checkbox = TestCheckbox.find('p');
    expect(checkbox.find('input[type="checkbox"]').length).toEqual(1);
  });

  it('sets proper input value through props', () => {
    let TestCheckbox = mount(
      <Provider store={reduxStore}>
        <Checkbox
          value={true}
        />
      </Provider>
    );
    let checkbox = TestCheckbox.find('p');
    expect(checkbox.find('input[type="checkbox"]').prop('checked')).toEqual(true);
    TestCheckbox = mount(
      <Provider store={reduxStore}>
        <Checkbox
          value={false}
        />
      </Provider>
    );
    checkbox = TestCheckbox.find('p');
    expect(checkbox.find('input[type="checkbox"]').prop('checked')).toEqual(false);
  });
});
