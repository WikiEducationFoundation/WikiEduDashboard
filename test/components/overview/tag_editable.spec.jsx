import React from 'react';
import { mount } from 'enzyme';
import { Provider } from 'react-redux';

import '../../testHelper';
import TagEditable from '../../../app/assets/javascripts/components/overview/tag_editable.jsx';

describe('TagEditable', () => {
  it('renders a plus button', () => {
    const wrapper = mount(
      <Provider store={reduxStore}>
        <TagEditable
          tags={[]}
          show={true}
        />
      </Provider>
    );
    const renderedButton = wrapper.find('button.plus');
    expect(renderedButton).toHaveLength(1);
    expect(renderedButton.prop('className')).toEqual('button border plus open');
    expect(renderedButton.text()).toEqual('+');
  });
});
