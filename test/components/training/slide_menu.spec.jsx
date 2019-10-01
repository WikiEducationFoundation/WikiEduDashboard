import React from 'react';
import { mount } from 'enzyme';
import { MemoryRouter, Route } from 'react-router-dom';
import configureMockStore from 'redux-mock-store';
import { Provider } from 'react-redux';
import thunk from 'redux-thunk';
import '../../testHelper';
import TrainingSlideHandler from '../../../app/assets/javascripts/training/components/training_slide_handler.jsx';
import SlideMenu from '../../../app/assets/javascripts/training/components/slide_menu.jsx';

jest.mock('../../../app/assets/javascripts/components/common/notifications.jsx', () => {
  return function Notifications() {
    return 'Notifications';
  };
});
const middlewares = [thunk];
const mockStore = configureMockStore(middlewares);

describe('SlideMenu', () => {
  const emptyFunction = function () {};
  const slide = {
    id: 1,
    enabled: true,
    title: 'How to Kitten',
    slug: 'kittens'
  };
  const store = mockStore({
    training: {
      loading: false,
      currentSlide: { content: 'hello', id: 'kittens' },
      slides: [slide],
      enabledSlides: [slide],
      nextSlide: { slug: 'foobar' }
    }
  });
  const TestMenu = mount(
    <Provider store={store}>
      <MemoryRouter initialEntries={['/training/foo/bar/kittens']}>
        <Route
          exact
          path="/training/:library_id/:module_id/:slide_id"
          render={() => (
            <TrainingSlideHandler loading={false}>
              <SlideMenu
                closeMenu={emptyFunction}
                onClick={emptyFunction}
              />
            </TrainingSlideHandler>
          )}
        />
      </MemoryRouter>
    </Provider>
  );

  it('renders an ol', () => {
    const list = TestMenu.find('ol').first();
    expect(list.children().length).toEqual(1);
  });

  it('links to a slide', () => {
    const menu = TestMenu.find(SlideMenu).first();
    const aTag = menu.find('a');
    expect(aTag.prop('href')).toEqual('/training/foo/bar/kittens');
  });
});
