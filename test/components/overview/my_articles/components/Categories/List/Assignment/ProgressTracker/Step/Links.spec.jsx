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

    expect(external.length).to.be.ok;
    expect(external.props().href).to.equal('/external');
    expect(external.text()).to.equal('external');

    expect(internal.length).to.be.ok;
    expect(internal.props().to).to.include('course/slug/internal');
    expect(internal.props().children).to.equal('internal');
  });
});
