import React from 'react';
import { shallow } from 'enzyme';
import '../../../../../../../../../testHelper';

import Description from '../../../../../../../../../../app/assets/javascripts/components/overview/my_articles/components/Categories/List/Assignment/ProgressTracker/Step/Description';

describe('Description', () => {
  it('displays the content', () => {
    const component = shallow(<Description content="content" />);
    expect(component.text()).to.include('content');
  });
});
