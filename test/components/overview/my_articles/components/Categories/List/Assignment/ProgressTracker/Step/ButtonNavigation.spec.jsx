import React from 'react';
import { shallow } from 'enzyme';
import '../../../../../../../../../testHelper';

import ButtonNavigation from '../../../../../../../../../../app/assets/javascripts/components/overview/my_articles/components/Categories/List/Assignment/ProgressTracker/Step/ButtonNavigation';

describe('ButtonNavigation', () => {
  const props = {
    active: true,
    assignment: {},
    course: {},
    courseSlug: 'course/slug',
    index: 1,
    updateAssignmentStatus: jest.fn(),
    fetchAssignments: jest.fn()
  };

  it('should show the Mark Complete button and Go Back a Step button', () => {
    const component = shallow(<ButtonNavigation {...props} />);
    const buttons = component.find('button');

    expect(buttons.length).toEqual(2);
    expect(buttons.at(0).text()).toContain('Go Back a Step');
    expect(buttons.at(1).text()).toContain('Mark Complete');
  });

  it('should not show the Go Back a Step button if it is the first step', () => {
    const component = shallow(<ButtonNavigation {...props} index={0} />);
    const buttons = component.find('button');

    expect(buttons.length).toEqual(1);
    expect(buttons.text()).toContain('Mark Complete');
  });

  it('should disable all buttons if the step is not active', () => {
    const component = shallow(<ButtonNavigation {...props} active={false} />);
    const buttons = component.find('button');

    expect(buttons.length).toEqual(2);
    expect(buttons.at(0).text()).toContain('Go Back a Step');
    expect(buttons.at(0).props().disabled).toEqual(true);
    expect(buttons.at(1).text()).toContain('Mark Complete');
    expect(buttons.at(1).props().disabled).toEqual(true);
  });
});
