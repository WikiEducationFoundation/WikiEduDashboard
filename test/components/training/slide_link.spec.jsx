import React from 'react';
import { mount } from 'enzyme';
import { Provider } from 'react-redux';
import thunk from 'redux-thunk';
import configureMockStore from 'redux-mock-store';
import '../../testHelper';
import SlideLink from '../../../app/assets/javascripts/training/components/slide_link.jsx';
import TrainingSlideHandler from '../../../app/assets/javascripts/training/components/training_slide_handler.jsx';

jest.mock('../../../app/assets/javascripts/components/common/notifications.jsx', () => 'Notifications');
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
    </Provider>
  );

  let domBtn;
  global.beforeEach(() => {
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
