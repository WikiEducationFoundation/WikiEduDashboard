import ReactTestUtils from 'react-dom/test-utils';
import React from 'react';

import '../../testHelper';
import TagEditable from '../../../app/assets/javascripts/components/overview/tag_editable.jsx';

describe('TagEditable', () => {
  it('renders a plus button', () => {
    const TestButton = ReactTestUtils.renderIntoDocument(
      <TagEditable
        store={reduxStore}
        tags={[]}
        show={true}
      />
    );
    const renderedButton = ReactTestUtils.findRenderedDOMComponentWithClass(TestButton, 'plus');
    expect(renderedButton.className).to.eq('button border plus open');
    expect(renderedButton.innerHTML).to.eq('+');
    expect(renderedButton.tagName.toLowerCase()).to.eq('button');
  });
});
