import React from 'react';
import { shallow } from 'enzyme';
import '../../../../../../../../../testHelper';

import EditorLink from '../../../../../../../../../../app/assets/javascripts/components/overview/my_articles/components/Categories/List/Assignment/Header/Links/EditorLink';

describe('EditorLink', () => {
  it('renders an AssignedToLink', () => {
    const component = shallow(<EditorLink />);
    expect(component.find('AssignedToLink').length).to.equal(1);
  });
});
