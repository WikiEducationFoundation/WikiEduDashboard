import React from 'react';
import { mount } from 'enzyme';
import { Provider } from 'react-redux';
import { MemoryRouter, Route } from 'react-router-dom';
import thunk from 'redux-thunk';
import configureMockStore from 'redux-mock-store';
import '../../testHelper';
import SlideLink from '../../../app/assets/javascripts/training/components/slide_link.jsx';
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
      currentSlide: { content: 'hello', id: 1 },
      slides: ['a'],
      enabledSlides: [],
      nextSlide: { slug: 'foobar' }
    }
  });
  const TestLink = mount(
    <Provider store={store}>
      <MemoryRouter initialEntries={['/training/foo/bar/kittens']}>
        <Route
          exact
          path="/training/:library_id/:module_id/:slide_id"
          render={({ match }) => (
            <TrainingSlideHandler
              loading={false}
            >
              <SlideLink
                slideId="foobar"
                buttonText="Next Page"
                disabled={false}
                button={true}
                onClick={jest.fn()}
                params={match.params}
              />
            </TrainingSlideHandler>
          )}
        />
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
