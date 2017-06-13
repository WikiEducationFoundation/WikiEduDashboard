import '../../testHelper';
import React from 'react';
import ReactTestUtils from 'react-addons-test-utils';
import ReactDOM from 'react-dom';

import SlideLink from '../../../app/assets/javascripts/training/components/slide_link.jsx';
import TrainingSlideHandler from '../../../app/assets/javascripts/training/components/training_slide_handler.jsx';
import ServerActions from '../../../app/assets/javascripts/actions/server_actions.js';
global.sinon.stub(ServerActions, 'fetchTrainingModule');

describe('SlideLink', () => {
  const TestLink = ReactTestUtils.renderIntoDocument(
    <TrainingSlideHandler
      loading={false}
      params={{ library_id: 'foo', module_id: 'bar', slide_id: 'foobar' }}
    >
      <SlideLink
        slideId="foobar"
        direction="Next"
        disabled={false}
        button={true}
        params={{ library_id: 'foo', module_id: 'bar' }}
      />
    </TrainingSlideHandler>
  );

  global.beforeEach(() =>
    TestLink.setState({
      loading: false,
      currentSlide: { content: 'hello', id: 1 },
      slides: ['a'],
      enabledSlides: [],
      nextSlide: { slug: 'foobar' }
    })
  );

  it('renders a button', () => {
    const button = ReactTestUtils.scryRenderedComponentsWithType(TestLink, SlideLink)[0];
    const domBtn = ReactDOM.findDOMNode(button);
    expect(domBtn.className).to.eq('slide-nav btn btn-primary icon icon-rt_arrow');
  });

  it('renders correct text', () => {
    const button = ReactTestUtils.scryRenderedComponentsWithType(TestLink, SlideLink)[0];
    const domBtn = ReactDOM.findDOMNode(button);
    expect(domBtn.textContent).to.eq('Next Page');
  });

  it('renders correct link', () => {
    const button = ReactTestUtils.scryRenderedComponentsWithType(TestLink, SlideLink)[0];
    const domBtn = ReactDOM.findDOMNode(button);
    const expected = '/training/foo/bar/foobar';
    // mocha won't render the link with an actual href for some reason…
    expect(domBtn.getAttribute('data-href')).to.eq(expected);
  });
});
