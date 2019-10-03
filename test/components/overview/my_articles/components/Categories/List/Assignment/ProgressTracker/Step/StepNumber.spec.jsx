import React from 'react';
import { shallow } from 'enzyme';
import '../../../../../../../../../testHelper';

import StepNumber from '../../../../../../../../../../app/assets/javascripts/components/overview/my_articles/components/Categories/List/Assignment/ProgressTracker/Step/StepNumber';

describe('StepNumber', () => {
  it('should render the step number', () => {
    const component = shallow(<StepNumber index={0} />);
    expect(component.text()).toEqual('1');
  });
});
