import React from 'react';
import { shallow } from 'enzyme';
import '../../../../../../../../../testHelper';

import Step from '../../../../../../../../../../app/assets/javascripts/components/overview/my_articles/components/Categories/List/Assignment/ProgressTracker/Step';

describe('Step', () => {
  const props = {
    assignment: {},
    content: 'content',
    courseSlug: 'course/slug',
    index: 1,
    status: 'status',
    title: 'title',
    trainings: [],

    updateAssignmentStatus: jest.fn(),
    fetchAssignments: jest.fn()
  };

  it('should display all the child components of a step', () => {
    const component = shallow(<Step {...props} />);

    expect(component.find('StepNumber').length).to.be.ok;
    expect(component.find('Title').length).to.be.ok;
    expect(component.find('Description').length).to.be.ok;
    expect(component.find('Links').length).to.be.ok;
    expect(component.find('ButtonNavigation').length).to.be.ok;
  });

  it('should show the Reviewers component if the status is ready_for_review', () => {
    const component = shallow(<Step {...props} status="ready_for_review" />);
    expect(component.find('Reviewers').length).to.be.ok;
  });

  it('should NOT be marked as active if the assignment status and step status do not match', () => {
    const component = shallow(
      <Step {...props} />
    );
    expect(component.props().className).to.not.include('active');
  });

  it('should be marked as active if the assignment status and step status match', () => {
    const component = shallow(
      <Step {...props} assignment={{ assignment_status: 'status' }} />
    );
    expect(component.props().className).to.include('active');
  });
});
