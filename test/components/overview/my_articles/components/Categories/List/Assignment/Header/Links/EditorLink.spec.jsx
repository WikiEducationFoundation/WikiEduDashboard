import React from 'react';
import { shallow } from 'enzyme';
import '../../../../../../../../../testHelper';

import EditorLink from '~/app/assets/javascripts/components/common/AssignmentLinks/EditorLink';

describe('EditorLink', () => {
  it('renders an AssignedToLink', () => {
    const component = shallow(<EditorLink />);
    expect(component).toMatchSnapshot();
  });
});
