import React from 'react';
import { shallow } from 'enzyme';
import '../../../../../../../testHelper';

import Tooltip from '../../../../../../../../app/assets/javascripts/components/overview/my_articles/components/Categories/List/Header/Tooltip';

describe('Tooltip', () => {
  it('should render', () => {
    const component = shallow(<Tooltip message="message" text="text" />);
    expect(component).toMatchSnapshot();
  });
});
