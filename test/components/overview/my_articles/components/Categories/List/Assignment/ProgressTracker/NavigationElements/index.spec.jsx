import React from 'react';
import { shallow } from 'enzyme';
import '../../../../../../../../../testHelper';

import NavigationElements from '../../../../../../../../../../app/assets/javascripts/components/overview/my_articles/components/Categories/List/Assignment/ProgressTracker/NavigationElements';

describe('NavigationElements', () => {
  const props = { assignment: {}, show: false };
  it('should show the down arrow when `show` is false', () => {
    const component = shallow(<NavigationElements {...props} />);
    const li = component.find('li');

    expect(li.length).to.equal(1);
    expect(li.props().className).to.include('icon-arrow');
  });

  it('should show the up arrow when `show` is true', () => {
    const component = shallow(<NavigationElements {...props} show={true} />);
    const li = component.find('li');

    expect(li.length).to.equal(1);
    expect(li.props().className).to.include('icon-arrow-reverse');
  });

  it('displays list items when given an assignment', () => {
    const component = shallow(
      <NavigationElements assignment={{ sandboxUrl: 'url' }} show={true} />
    );
    const listItem = component.find('ListItem');
    expect(listItem.length).to.be.ok;
  });
});
