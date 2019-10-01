import React from 'react';
import { shallow } from 'enzyme';
import '../../../../../../../../../testHelper';

import Title from '../../../../../../../../../../app/assets/javascripts/components/overview/my_articles/components/Categories/List/Assignment/ProgressTracker/Step/Title';

describe('Title', () => {
  it('renders the title', () => {
    const component = shallow(<Title title="title" />);
    expect(component.text()).toEqual('title');
  });
});
