import React from 'react';
import { mount } from 'enzyme';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import configureMockStore from 'redux-mock-store';
import { Provider } from 'react-redux';
import thunk from 'redux-thunk';
import '../../testHelper';
import TrainingLibraries from '../../../app/assets/javascripts/training/components/training_libraries_list.jsx';
import { I18n } from 'i18n-js';

const middlewares = [thunk];
const mockStore = configureMockStore(middlewares);

describe('SlideMenu', () => {
  const libraries = [
        {
        id: 1,
        slug: 'puppies',
        name: 'Puppies',
        wiki_page: 'Puppies',
        introduction: 'Learn how to puppy',
        categories: [
          {
            title: 'Puppies',
            description: 'Learn how to puppy',
            modules: [
              {
                slug: 'puppies',
                name: 'Puppies',
                description: 'Learn how to puppy',
              },
                {
                    slug: 'puppies2',
                    name: 'Puppies2',
                    description: 'Learn how to puppy',
              }
            ]
          }
        ]
        },
        {
            id: 2,
            slug: 'kittens',
            name: 'Kittens',
            wiki_page: 'Kittens',
            introduction: 'Learn how to kitten',
            categories: [
                {
                    title: 'Kittens',
                    description: 'Learn how to kitten',
                    modules: [
                        {
                            slug: 'kittens',
                            name: 'Kittens',
                            description: 'Learn how to kitten',
                        }
                    ]
                }
            ]
        }
    ];
  const user = {
    id: 1,
    username: 'JohnDoe',
    created_at: '2015-09-30T15:26:29.000Z',
    updated_at: '2015-09-30T15:26:29.000Z',
    trained: false,
    global_id: '12345',
    wiki_token: 'foo',
    wiki_secret: 'bar',
    permissions: 0,
    real_name: 'John Doe',
    email: 'johndoe@gmail.com',
    onboarded: true,
  };
  it('renders libraries for a logged in user', () => {
    const store = mockStore({
        training: {
            loading: false,
            libraries: libraries,
            focusedLibrarySlug: 'puppies',
        },
        user,
        });
    const wrapper = mount(
      <Provider store={store}>
        <MemoryRouter initialEntries={['/training']}>
          <Routes>
            <Route
              path="/training"
              element={
                <TrainingLibraries />
                        }
            />
          </Routes>
        </MemoryRouter>
      </Provider>
    );
    const list = wrapper.find('ul.training_libraries');
    expect(list.children().length).toEqual(libraries.length);
});
it('renders libraries for a logged out user', () => {
    const store = mockStore({
        training: {
            loading: false,
            libraries: libraries,
            focusedLibrarySlug: 'puppies',
        },
        user: {},
    });
    const wrapper = mount(
      <Provider store={store}>
        <MemoryRouter initialEntries={['/training']}>
          <Routes>
            <Route
              path="/training"
              element={
                <TrainingLibraries />
                        }
            />
          </Routes>
        </MemoryRouter>
      </Provider>
    );
    const list = wrapper.find('ul.training_libraries');
    expect(list.children().length).toEqual(libraries.length);
});
it('renders a loading spinner', () => {
    const store = mockStore({
        training: {
            loading: true,
            libraries: [],
            focusedLibrarySlug: 'puppies',
        },
        user,
    });
    const wrapper = mount(
      <Provider store={store}>
        <MemoryRouter initialEntries={['/training']}>
          <Routes>
            <Route
              path="/training"
              element={
                <TrainingLibraries />
                        }
            />
          </Routes>
        </MemoryRouter>
      </Provider>
    );
    const list = wrapper.find('ul.training_libraries');
    expect(list.children().length).toEqual(0);
});
it('renders no libraries message for logged in user in wiki_ed mode', () => {
    const store = mockStore({
        training: {
            loading: false,
            libraries: [],
            focusedLibrarySlug: 'puppies',
        },
        user,
    });
    const wrapper = mount(
      <Provider store={store}>
        <MemoryRouter initialEntries={['/training']}>
          <Routes>
            <Route
              path="/training"
              element={
                <TrainingLibraries />
              }
            />
          </Routes>
        </MemoryRouter>
      </Provider>
    );

    const noLibrariesMessage = wrapper.find('div').text();
    const expectedMessage = Features.WikiEd
      ? I18n.t('training.no_training_library_records_wiki_ed_mode', {
        url: '/reload_trainings?module=all',
      })
      : I18n.t('training.no_training_library_records_non_wiki_ed_mode');

    expect(noLibrariesMessage).toContain(expectedMessage);
});
it('renders a search input', () => {
    const store = mockStore({
      training: {
        loading: false,
        libraries: libraries,
        focusedLibrarySlug: 'puppies',
      },
      user,
    });

    const wrapper = mount(
      <Provider store={store}>
        <MemoryRouter initialEntries={['/training']}>
          <Routes>
            <Route
              path="/training"
              element={<TrainingLibraries />}
            />
          </Routes>
        </MemoryRouter>
      </Provider>
    );

    const searchInput = wrapper.find('#search_training');
    expect(searchInput.exists()).toBe(true);
  });

  it('renders search results', () => {
    const store = mockStore({
      training: {
        loading: false,
        libraries: libraries,
        focusedLibrarySlug: 'puppies',
      },
      user,
    });

    const wrapper = mount(
      <Provider store={store}>
        <MemoryRouter initialEntries={['/training']}>
          <Routes>
            <Route
              path="/training"
              element={<TrainingLibraries />}
            />
          </Routes>
        </MemoryRouter>
      </Provider>
    );

    wrapper.find('#search_training').simulate('change', { target: { value: 'search term' } });
    wrapper.find('#training_search_button').simulate('click');

    const searchResults = wrapper.find('.search-results');
    expect(searchResults.exists()).toBe(true);
  });
});
