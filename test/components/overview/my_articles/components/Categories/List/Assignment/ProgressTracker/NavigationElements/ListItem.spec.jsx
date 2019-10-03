import React from 'react';
import { shallow } from 'enzyme';
import '../../../../../../../../../testHelper';

import ListItem from '../../../../../../../../../../app/assets/javascripts/components/overview/my_articles/components/Categories/List/Assignment/ProgressTracker/NavigationElements/ListItem';

describe('ListItem', () => {
  const props = {
    assignment: {},
    index: 0,
    status: 'status',
    title: 'title'
  };

  it('should display the title', () => {
    const component = shallow(<ListItem {...props} />);
    expect(component.text()).toContain('1. title');
  });

  it('should be marked as selected when the assignment_status matches the step status', () => {
    const component = shallow(
      <ListItem {...props} assignment={{ assignment_status: 'status' }} />
    );
    expect(component.props().className).toContain('selected');
  });
});
