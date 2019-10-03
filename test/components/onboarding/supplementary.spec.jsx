import React from 'react';
import { shallow } from 'enzyme';

import { OnboardingSupplementary as Supplementary } from '../../../app/assets/javascripts/components/onboarding/supplementary.jsx';
import OnboardingAPI from '../../../app/assets/javascripts/utils/onboarding_utils.js';
import '../../testHelper';

describe('Supplementary', () => {
  global.$ = () => ({ data: () => ({ username: 'myUsername' }) });
  const mockAddNotification = jest.fn();
  const component = shallow(<Supplementary addNotification={mockAddNotification}/>);

  afterEach(() => {
    component.instance().setState({
      heardFrom: '',
      referralDetails: '',
      whyHere: '',
      otherReason: ''
    });
  });

  it('will load the supplementary form with required elements', () => {
    const elements = [
      'h1',
      'form',
      'input[type="radio"][name="heardFrom"]',
      'input[type="radio"][name="whyHere"]',
      'button[type="submit"]'
    ];

    elements.forEach((el) => {
      const err = `${el} is missing from the form`;
      expect(component.find(el).length).toBeGreaterThan(0, err);
    });
  });

  it('shows another text field if anything but "web" is in selected', () => {
    const heardFromValues = [
      'colleague',
      'association',
      'conference',
      'workshop',
      'other'
    ];

    heardFromValues.forEach((heardFrom) => {
      const err = `Did not show additional text field for ${heardFrom}`;
      component.instance().setState({ heardFrom });
      expect(component.find('#referralDetails').length).toEqual(1, err);
    });

    component.instance().setState({ heardFrom: 'web' });
    expect(component.find('#referralDetails').length).toEqual(0);
  });

  it('changes the additional text field label based on the selection', () => {
    const heardFromValues = [
      'colleague',
      'association',
      'conference',
      'workshop',
      'other'
    ];

    heardFromValues.forEach((heardFrom) => {
      component.instance().setState({ heardFrom });
      const label = component.find('[htmlFor="referralDetails"]');
      expect(label.text().toLowerCase()).toContain(heardFrom);
    });
  });

  it('sends data to the API upon submit', () => {
    OnboardingAPI.supplement = jest.fn(() => Promise.resolve());
    const formData = {
      heardFrom: 'colleague',
      referralDetails: 'name of friend',
      whyHere: 'learn about teaching',
      otherReason: 'no reason'
    };

    component.instance().setState(formData);
    component.find('form').simulate('submit', { preventDefault: () => {} });
    expect(OnboardingAPI.supplement).toBeCalled();
    expect(OnboardingAPI.supplement).toBeCalledWith({ ...formData, user_name: 'myUsername' });
  });

  it('adds a notification if there is a problem', () => {
    OnboardingAPI.supplement = jest.fn(() => Promise.reject());

    component.find('form').simulate('submit', { preventDefault: () => { } });
    expect(OnboardingAPI.supplement).toBeCalled();
    expect(mockAddNotification).toBeCalled();
  });
});
