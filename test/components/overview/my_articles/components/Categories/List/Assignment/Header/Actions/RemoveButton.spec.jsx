import React from 'react';
import { shallow } from 'enzyme';
import '../../../../../../../../../testHelper';

import RemoveButton from '../../../../../../../../../../app/assets/javascripts/components/overview/my_articles/components/Categories/List/Assignment/Header/Actions/RemoveButton';

describe('RemoveButton', () => {
  const unassign = jest.fn();
  const props = {
    assignment: {},
    unassign
  };
  const component = shallow(<RemoveButton {...props} />);

  it('renders the button', () => {
    expect(component.text()).to.equal('Remove');
  });

  it('calls the unassign function when clicked', () => {
    const button = component.find('button');
    button.props().onClick();

    expect(unassign.mock.calls.length).to.equal(1);
  });
});
