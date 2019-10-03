import React from 'react';
import { shallow } from 'enzyme';
import '../../../../../../../../../testHelper';

import Links from '../../../../../../../../../../app/assets/javascripts/components/overview/my_articles/components/Categories/List/Assignment/ProgressTracker/Step/Links';

describe('Links', () => {
  const props = {
    courseSlug: 'course/slug',
    trainings: [
      { external: false, path: 'internal', title: 'internal' },
      { external: true, path: '/external', title: 'external' },
    ]
  };

  it('should display links of various types', () => {
    const component = shallow(<Links {...props} />);
    const external = component.find('a');
    const internal = component.find('HashLink');

    expect(external.length).toBeTruthy;
    expect(external.props().href).toEqual('/external');
    expect(external.text()).toEqual('external');

    expect(internal.length).toBeTruthy;
    expect(internal.props().to).toContain('course/slug/internal');
    expect(internal.props().children).toEqual('internal');
  });
});
