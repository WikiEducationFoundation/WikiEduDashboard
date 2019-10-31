import React from 'react';
import { shallow } from 'enzyme';
import '../../../../../../../../../testHelper';

import NavigationElements from '@components/overview/my_articles/components/Categories/List/Assignment/ProgressTracker/NavigationElements/NavigationElements.jsx';

describe('NavigationElements', () => {
  const props = { assignment: {}, show: false };
  it('should show the down arrow when `show` is false', () => {
    const component = shallow(<NavigationElements {...props} />);
    const li = component.find('li');

    expect(li.length).toEqual(1);
    expect(li.props().className).toContain('icon-arrow');
  });

  it('should show the up arrow when `show` is true', () => {
    const component = shallow(<NavigationElements {...props} show={true} />);
    const li = component.find('li');

    expect(li.length).toEqual(1);
    expect(li.props().className).toContain('icon-arrow-reverse');
  });

  it('displays list items when given an assignment', () => {
    const component = shallow(
      <NavigationElements assignment={{ sandboxUrl: 'url' }} show={true} />
    );
    const listItem = component.find('ListItem');
    expect(listItem.length).toBeTruthy;
  });
});
