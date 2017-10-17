import 'testHelper';
import React from 'react';
import { mount } from 'enzyme';
import FinalArticleChecklist from 'components/common/final_article_checklist';

describe('FinalArticleChecklist', () => {
  it('renders checklist when button is clicked', () => {
    const component = mount(<FinalArticleChecklist />);
    // Because this component is wrapped in OnClickOutside, we must use
    // its getInstance method to access the component itself and inspect its
    // state.
    expect(component.instance().getInstance().state.show).to.eq(false);
    // click the initial button to show the modal
    component.find('.button').simulate('click');
    expect(component.instance().getInstance().state.show).to.eq(true);
    // trigger the outside click handler to close the modal
    component.instance().getInstance().handleClickOutside();
    expect(component.instance().getInstance().state.show).to.eq(false);
  });
});
