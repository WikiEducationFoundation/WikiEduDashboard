import React from 'react';
import { shallow } from 'enzyme';
import '../../../../../../../../testHelper';

import ProgressTracker from '@components/overview/my_articles/components/Categories/List/Assignment/ProgressTracker/ProgressTracker';

describe('ProgressTracker', () => {
  const props = {
    assignment: {},
    course: { slug: 'course/slug' },
    updateAssignmentStatus: jest.fn(),
    fetchAssignments: jest.fn()
  };

  it('shows the progress tracker navigation', () => {
    const component = shallow(<ProgressTracker {...props} />);
    const tracker = component.find('.toggle-progress-tracker');
    expect(tracker.length).toBeTruthy;
  });

  it('does not show steps on load', () => {
    const component = shallow(<ProgressTracker {...props} />);
    expect(component.find('.flow').children().length).toEqual(0);
  });

  it('shows the steps after clicking on the navigation', () => {
    const component = shallow(<ProgressTracker {...props} />);
    expect(component.find('Step').length).toBeFalsy;

    const tracker = component.find('.toggle-progress-tracker');
    tracker.props().onClick();
    component.update();

    expect(component.find('Step').length).toBeTruthy;
  });
});
