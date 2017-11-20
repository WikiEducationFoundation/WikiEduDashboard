import '../../testHelper';
import React from 'react';
import { mount } from 'enzyme';
import SlideLink from '../../../app/assets/javascripts/training/components/slide_link.jsx';
import TrainingSlideHandler from '../../../app/assets/javascripts/training/components/training_slide_handler.jsx';
import ServerActions from '../../../app/assets/javascripts/actions/server_actions.js';
global.sinon.stub(ServerActions, 'fetchTrainingModule');

describe('SlideLink', () => {
  const TestLink = mount(
    <TrainingSlideHandler
      loading={false}
      params={{ library_id: 'foo', module_id: 'bar', slide_id: 'foobar' }}
    >
      <SlideLink
        slideId="foobar"
        buttonText="Next Page"
        disabled={false}
        button={true}
        params={{ library_id: 'foo', module_id: 'bar' }}
      />
    </TrainingSlideHandler>
  );

  let domBtn;
  global.beforeEach(() => {
    TestLink.setState({
      loading: false,
      currentSlide: { content: 'hello', id: 1 },
      slides: ['a'],
      enabledSlides: [],
      nextSlide: { slug: 'foobar' }
    });

    domBtn = TestLink.find('.slide-nav').first();
  });

  it('renders a button', () => {
    expect(domBtn.prop('className')).to.eq('slide-nav btn btn-primary icon icon-rt_arrow');
  });

  it('renders correct text', () => {
    expect(domBtn.text()).to.eq('Next Page');
  });

  it('renders correct link', () => {
    const expected = '/training/foo/bar/foobar';
    // mocha won't render the link with an actual href for some reason…
    expect(domBtn.prop('data-href')).to.eq(expected);
  });
});
