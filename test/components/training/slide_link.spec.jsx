import React from 'react';
import { mount } from 'enzyme';
import { Provider } from 'react-redux';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import thunk from 'redux-thunk';
import configureMockStore from 'redux-mock-store';
import '../../testHelper';
import TrainingSlideHandler from '../../../app/assets/javascripts/training/components/training_slide_handler.jsx';

jest.mock('../../../app/assets/javascripts/components/common/notifications.jsx', () => {
  return function Notifications() {
    return 'Notifications';
  };
});
const middlewares = [thunk];
const mockStore = configureMockStore(middlewares);
describe('SlideLink', () => {
  const store = mockStore({
    training: {
      loading: false,
      currentSlide: { content: 'hello', id: 1, buttonText: 'Next Page' },
      slides: ['a'],
      enabledSlides: [],
      nextSlide: { slug: 'foobar' }
    }
  });
  const TestLink = mount(
    <Provider store={store}>
      <MemoryRouter initialEntries={['/training/foo/bar/kittens']}>
        <Routes>
          <Route
            path="/training/:library_id/:module_id/:slide_id"
            element={<TrainingSlideHandler/>}
          />
        </Routes>
      </MemoryRouter>
    </Provider>
  );

  let domBtn;
  global.beforeEach(() => {
    domBtn = TestLink.find('.slide-nav').first();
  });

  it('renders a button', () => {
    expect(domBtn.prop('className')).toEqual('slide-nav btn btn-primary icon icon-rt_arrow');
  });

  it('renders correct text', () => {
    expect(domBtn.text()).toEqual('Next Page');
  });

  it('renders correct link', () => {
    const expected = '/training/foo/bar/foobar';
    // mocha won't render the link with an actual href for some reason…
    expect(domBtn.prop('data-href')).toEqual(expected);
  });
});
