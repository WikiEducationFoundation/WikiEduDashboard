import '../../testHelper';
import TrainingSlideHandler from '../../../app/assets/javascripts/training/components/training_slide_handler.jsx';
import SlideMenu from '../../../app/assets/javascripts/training/components/slide_menu.jsx';
import React from 'react';
import ReactTestUtils from 'react-addons-test-utils';
import ReactDOM from 'react-dom';

describe('SlideMenu', () => {
  const emptyFunction = function () { };
  const params = { library_id: 'foo', module_id: 'bar', slide_id: 'kittens' };
  const slide = { id: 1, enabled: true, title: 'How to Kitten', slug: 'kittens' };
  const TestMenu = ReactTestUtils.renderIntoDocument(
    <TrainingSlideHandler
      loading={false}
      params={params}
    >
      <SlideMenu params={params} closeMenu={emptyFunction} onClick={emptyFunction} />
    </TrainingSlideHandler>
  );

  global.beforeEach(() =>
    TestMenu.setState({
      loading: false,
      currentSlide: { content: 'hello', id: 'kittens' },
      slides: [slide],
      enabledSlides: [slide],
      nextSlide: { slug: 'foobar' }
    }
    )
  );

  it('renders an ol', () => {
    const menu = ReactTestUtils.scryRenderedComponentsWithType(TestMenu, SlideMenu)[0];
    const menuNode = ReactDOM.findDOMNode(menu);
    expect($(menuNode).find('ol').length).to.eq(1);
  });

  it('links to a slide', () => {
    const menu = ReactTestUtils.scryRenderedComponentsWithType(TestMenu, SlideMenu)[0];
    const menuNode = ReactDOM.findDOMNode(menu);
    expect($(menuNode).find('a').attr('href')).to.eq('/training/foo/bar/kittens');
  });
});
