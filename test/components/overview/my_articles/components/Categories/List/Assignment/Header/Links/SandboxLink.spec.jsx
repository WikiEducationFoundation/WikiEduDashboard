import React from 'react';
import { shallow } from 'enzyme';
import '../../../../../../../../../testHelper';

import SandboxLink from '~/app/assets/javascripts/components/common/AssignmentLinks/SandboxLink';

describe('SandboxLink', () => {
  Features.wikiEd = true;

  it('should show the link', () => {
    const component = shallow(<SandboxLink assignment={{ sandboxUrl: 'url' }} />);
    expect(component).toMatchSnapshot();
    expect(component.find('a').props().href).toContain('url');
  });

  it('should include a template in the link if the assignment is a new article', () => {
    const component = shallow(<SandboxLink assignment={{ status: 'new_article' }} />);
    expect(component).toMatchSnapshot();
    expect(component.find('a').props().href).toContain('Template');
  });
});
