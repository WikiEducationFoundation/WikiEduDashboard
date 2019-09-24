import React from 'react';
import { shallow } from 'enzyme';
import '../../../../../../../testHelper';

import Header from '../../../../../../../../app/assets/javascripts/components/overview/my_articles/components/Categories/List/Header';

describe('Header', () => {
  it('renders the title, message, and tooltip', () => {
    const component = shallow(
      <Header message="message" sub="subtext" title="title" />
    );

    expect(component.text()).includes('title');
    expect(component.find('Tooltip').length).to.equal(1);
  });

  it('renders just the title if there is no message for the tooltip', () => {
    const component = shallow(<Header title="title" />);

    expect(component.text()).includes('title');
    expect(component.find('Tooltip').length).to.not.equal(1);
  });
});
