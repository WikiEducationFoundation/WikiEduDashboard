import React from 'react';
import { shallow } from 'enzyme';
import '../../../../../../../../../testHelper';

import SandboxLink from '../../../../../../../../../../app/assets/javascripts/components/overview/my_articles/components/Categories/List/Assignment/Header/Links/SandboxLink';

describe('SandboxLink', () => {
  it('should show the link', () => {
    const component = shallow(<SandboxLink assignment={{ sandboxUrl: 'url' }} />);
    expect(component.find('a').props().href).to.equal('url');
  });

  it('should include a template in the link if the assignment is a new article', () => {
    const component = shallow(<SandboxLink assignment={{ status: 'new_article' }} />);
    expect(component.find('a').props().href).to.include('Template');
  });
});
