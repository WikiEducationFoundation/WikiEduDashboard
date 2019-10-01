import React from 'react';
import { shallow } from 'enzyme';
import '../../../../../../../../../testHelper';

import Reviewers from '../../../../../../../../../../app/assets/javascripts/components/overview/my_articles/components/Categories/List/Assignment/ProgressTracker/Step/Reviewers';

describe('Reviewers', () => {
  it('shows nothing if there are no reviewers', () => {
    const component = shallow(<Reviewers reviewers={null} />);
    expect(component.children().length).toEqual(0);
  });

  it('renders if there are reviewers', () => {
    const component = shallow(<Reviewers reviewers={[]} />);
    expect(component.children().length).toBeTruthy;
  });
});
