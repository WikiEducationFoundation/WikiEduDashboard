import '../../testHelper';
import TrainingSlideHandler from '../../../app/assets/javascripts/training/components/training_slide_handler.jsx';
import SlideMenu from '../../../app/assets/javascripts/training/components/slide_menu.jsx';
import React from 'react';
import { mount } from 'enzyme';

describe('SlideMenu', () => {
  const emptyFunction = function () { };
  const params = { library_id: 'foo', module_id: 'bar', slide_id: 'kittens' };
  const slide = { id: 1, enabled: true, title: 'How to Kitten', slug: 'kittens' };
  const TestMenu = mount(
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
    })
  );

  it('renders an ol', () => {
    const list = TestMenu.find('ol').first();
    expect(list.children().length).to.eq(1);
  });

  it('links to a slide', () => {
    const menu = TestMenu.find(SlideMenu).first();
    const aTag = menu.find('a');
    expect(aTag.prop('href')).to.eq('/training/foo/bar/kittens');
  });
});
