import React from 'react';
import { shallow } from 'enzyme';
import '../../../../../../../../../testHelper';

import MarkAsIncompleteButton from '../../../../../../../../../../app/assets/javascripts/components/overview/my_articles/components/Categories/List/Assignment/Header/Actions/MarkAsIncompleteButton';

describe('MarkAsIncompleteButton', () => {
  const update = jest.fn();
  const props = {
    assignment: { assignment_all_statuses: [] },
    courseSlug: 'course/slug',
    handleUpdateAssignment: update,
    refreshAssignments: jest.fn()
  };
  it('should show the button', () => {
    const component = shallow(<MarkAsIncompleteButton {...props} />);
    expect(component.text()).to.equal('Mark as Incomplete');
  });

  it('should update the assignment on button click', async () => {
    const component = shallow(<MarkAsIncompleteButton {...props} />);
    const button = component.find('button');

    await button.props().onClick();
    expect(update.mock.calls.length).to.equal(1);
  });
});
