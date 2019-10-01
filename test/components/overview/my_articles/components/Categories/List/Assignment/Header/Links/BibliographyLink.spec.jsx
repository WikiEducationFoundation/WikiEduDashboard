import React from 'react';
import { shallow } from 'enzyme';
import '../../../../../../../../../testHelper';

import BibliographyLink from '../../../../../../../../../../app/assets/javascripts/components/overview/my_articles/components/Categories/List/Assignment/Header/Links/BibliographyLink';

describe('BibliographyLink', () => {
  const props = { assignment: { sandboxUrl: 'url' } };
  it('should display the link', () => {
    const component = shallow(<BibliographyLink {...props} />);
    expect(component.props().href).toContain('url/Bibliography');
  });
});
