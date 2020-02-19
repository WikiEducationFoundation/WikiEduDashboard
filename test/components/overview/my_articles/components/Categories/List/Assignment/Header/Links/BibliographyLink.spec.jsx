import React from 'react';
import { shallow } from 'enzyme';
import '../../../../../../../../../testHelper';

import BibliographyLink from '~/app/assets/javascripts/components/common/AssignmentLinks/BibliographyLink';

describe('BibliographyLink', () => {
  it('should display the link', () => {
    const props = { assignment: { sandboxUrl: 'url' } };
    const component = shallow(<BibliographyLink {...props} />);
    expect(component).toMatchSnapshot();
    expect(component.props().href).toContain('url/Bibliography');
  });
});
