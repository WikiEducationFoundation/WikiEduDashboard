import React from 'react';
import configureMockStore from 'redux-mock-store';
import { Provider } from 'react-redux';
import { mount } from 'enzyme';

import thunk from 'redux-thunk';

import '../../testHelper';
import TrainingSlideHandler from '../../../app/assets/javascripts/training/components/training_slide_handler.jsx';
import SlideMenu from '../../../app/assets/javascripts/training/components/slide_menu.jsx';

const middlewares = [thunk];
const mockStore = configureMockStore(middlewares);

describe('SlideMenu', () => {
  const emptyFunction = function () { };
  const params = { library_id: 'foo', module_id: 'bar', slide_id: 'kittens' };
  const slide = { id: 1, enabled: true, title: 'How to Kitten', slug: 'kittens' };
  const store = mockStore({
  });
  const TestMenu = mount(
    <Provider store={store}>
      <TrainingSlideHandler
        loading={false}
        params={params}
      >
        <SlideMenu params={params} closeMenu={emptyFunction} onClick={emptyFunction} />
      </TrainingSlideHandler>
    </Provider>
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
