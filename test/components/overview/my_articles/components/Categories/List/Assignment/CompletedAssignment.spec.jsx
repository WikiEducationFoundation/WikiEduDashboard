import React from 'react';
import { shallow } from 'enzyme';
import '../../../../../../../testHelper';

import CompletedAssignment from '../../../../../../../../app/assets/javascripts/components/overview/my_articles/components/Categories/List/Assignment/CompletedAssignment';

describe('CompletedAssignment', () => {
  it('should render', () => {
    const component = shallow(<CompletedAssignment />);
    expect(component.text()).toContain('You\'ve marked your article as complete.');
  });
});
