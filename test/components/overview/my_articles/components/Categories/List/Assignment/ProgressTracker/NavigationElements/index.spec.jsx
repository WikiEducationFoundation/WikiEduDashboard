import React from 'react';
import { shallow } from 'enzyme';
import '../../../../../../../../../testHelper';

import NavigationElements from '@components/overview/my_articles/components/Categories/List/Assignment/ProgressTracker/NavigationElements/NavigationElements.jsx';

describe('NavigationElements', () => {
  const props = { assignment: {}, showTracker: false };
  it('should show the down arrow when `showTracker` is false', () => {
    const component = shallow(<NavigationElements {...props} />);
    const li = component.find('li');

    expect(li.length).toEqual(1);
    expect(li.props().className).toContain('icon-arrow');
  });

  it('should show the up arrow when `showTracker` is true', () => {
    const component = shallow(<NavigationElements {...props} showTracker={true} />);
    const li = component.find('li');

    expect(li.length).toEqual(1);
    expect(li.props().className).toContain('icon-arrow-reverse');
  });

  it('displays list items when given an assignment', () => {
    const component = shallow(
      <NavigationElements assignment={{ sandboxUrl: 'url' }} showTracker={true} />
    );
    const listItem = component.find('ListItem');
    expect(listItem.length).toBeTruthy;
  });
});
