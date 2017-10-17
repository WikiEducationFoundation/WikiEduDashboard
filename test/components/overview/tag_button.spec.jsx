import '../../testHelper';
import React from 'react';
import ReactTestUtils from 'react-dom/test-utils';
import TagButton from '../../../app/assets/javascripts/components/overview/tag_button.jsx';

describe('TagButton', () =>
  it('renders a plus button', () => {
    const TestButton = ReactTestUtils.renderIntoDocument(
      <TagButton
        tags={[]}
        show={true}
      />
    );
    const renderedButton = ReactTestUtils.findRenderedDOMComponentWithClass(TestButton, 'plus');
    expect(renderedButton.className).to.eq('button border plus');
    expect(renderedButton.innerHTML).to.eq('+');
    expect(renderedButton.tagName.toLowerCase()).to.eq('button');
  })
);
