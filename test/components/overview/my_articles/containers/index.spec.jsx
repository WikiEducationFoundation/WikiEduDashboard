import React from 'react';
import { mount } from 'enzyme';
import { Provider } from 'react-redux';
import { MemoryRouter } from 'react-router';
import configureMockStore from 'redux-mock-store';

import '../../../../testHelper';
import MyArticlesContainer from '../../../../../app/assets/javascripts/components/overview/my_articles/containers';

describe('MyArticlesContainer', () => {
  describe('Features.wikiEd = true', () => {
    Features.wikiEd = true;
    const initialState = {
      assignments: { assignments: [], loading: false },
      course: {
        home_wiki: { language: 'en', project: 'wikipedia' },
        slug: 'course/slug',
        type: 'ClassroomProgramCourse'
      },
      wikidataLabels: {},
      ui: {}
    };

    it('displays a message if there are no assignments', () => {
      const store = configureMockStore()(initialState);

      const props = {
        current_user: { isStudent: true, username: 'Username' }
      };

      const Container = mount(
        <Provider store={store}>
          <MemoryRouter>
            <MyArticlesContainer {...props} />
          </MemoryRouter>
        </Provider>
      );

      // This checks that nothing gets rendered.
      expect(Container.children().length).toEqual(1);
      expect(Container.text()).toMatch(/You have not chosen an article/);
    });

    it('does not display for an admin', () => {
      const store = configureMockStore()(initialState);

      const props = {
        current_user: { isStudent: false, username: 'Username' }
      };

      const Container = mount(
        <Provider store={store}>
          <MyArticlesContainer {...props} />
        </Provider>
      );

      // This checks that nothing gets rendered.
      expect(Container.children().length).toEqual(1);
      expect(Container.children().at(0).type()).toEqual(MyArticlesContainer);
    });

    describe('rendering', () => {
      const store = configureMockStore()({
        assignments: {
          assignments: [
            {
              article_id: 99,
              article_rating: 'b',
              article_status: 'improving_article',
              article_title: 'My Article Title',
              article_url: 'https://en.wikipedia.org/wiki/My_Article_Title_from_URL',
              assignment_all_statuses: ['not_yet_started', 'in_progress'],
              assignment_id: 9,
              assignment_status: 'not_yet_started',
              id: 1,
              role: 0,
              sandboxUrl: 'http://sandbox_url',
              user_id: 1,
              username: 'Username',
            }
          ],
          loading: false
        },
        course: {
          home_wiki: { language: 'en', project: 'wikipedia' },
          slug: 'course/slug',
          type: 'ClassroomProgramCourse'
        },
        feedback: {},
        wikidataLabels: {},
        ui: { openKey: true }
      });

      const props = {
        current_user: { id: 1, isStudent: true, username: 'Username' }
      };

      const Container = mount(
        <Provider store={store}>
          <MemoryRouter>
            <MyArticlesContainer {...props} />
          </MemoryRouter>
        </Provider>
      );

      it('shows the header', () => {
        expect(Container.find('.my-articles-header').length).toEqual(1);
        expect(Container.find('.my-articles-header').text()).toContain('My Articles');
      });

      it('shows the assignment listing (categories)', () => {
        expect(Container.find('Categories').length).toEqual(1);
        expect(Container.find('Categories').text()).toContain('Articles I\'m updating');
      });

      xit('shows the My Articles section if the student has any', () => {
        expect(Container.find('Heading').length).toEqual(1);
        expect(Container.find('Heading').text()).toContain('Articles I\'m updating');
      });

      xit('shows the assignment title and related links', () => {
        expect(Container.find('.title').text()).toEqual('My Article Title from URL');

        const sandboxUrl = props.assignments[0].sandboxUrl;
        const bibliography = Container.find('BibliographyLink a');
        expect(bibliography.length).toBeTruthy;
        expect(bibliography.props().href).toContain(sandboxUrl);
        expect(bibliography.props().href).toContain('Bibliography');

        const sandbox = Container.find('SandboxLink a');
        expect(sandbox.length).toBeTruthy;
        expect(sandbox.props().href).toContain(sandboxUrl);
      });

      xit('shows the assignment title and related links', () => {
        expect(Container.find('.title').text()).toEqual('My Article Title from URL');

        const sandboxUrl = props.assignments[0].sandboxUrl;
        const bibliography = Container.find('BibliographyLink a');
        expect(bibliography.length).toBeTruthy;
        expect(bibliography.props().href).toContain(sandboxUrl);
        expect(bibliography.props().href).toContain('Bibliography');

        const sandbox = Container.find('SandboxLink a');
        expect(sandbox.length).toBeTruthy;
        expect(sandbox.props().href).toContain(sandboxUrl);
      });

      xit('hides the progress tracker on load, shows on state change', () => {
        expect(Container.find('section.flow').props().className).toContain('hidden');

        const nav = Container.find('nav.toggle-wizard');
        nav.props().onClick();
        Container.update();

        expect(Container.find('section.flow').props().className).not.toContain('hidden');
      });

      xit('shows the progress tracker with buttons to move ahead', () => {
        const wizard = Container.find('Wizard');
        wizard.setState({ show: true });
        expect(Container.find('section.flow').props().className).not.toContain('hidden');

        const steps = wizard.find('Step');
        expect(steps.length).toEqual(4);
        expect(steps.at(0).find('.step').props().className).toContain('active');
        expect(steps.at(1).find('.step').props().className).not.toContain('active');

        const buttons = wizard.find('ButtonNavigation');
        expect(buttons.length).toEqual(4);
        // The first step should only have a button to move forward
        // and should be enabled by default.
        expect(buttons.at(0).find('button').length).toEqual(1);
        expect(buttons.at(0).find('button').props().disabled).to.be.false;
        // The second step should have a button to move forward and backwards
        // and should be disabled.
        expect(buttons.at(1).find('button').length).toEqual(2);
        expect(buttons.at(1).find('button').at(0).props().disabled).to.be.true;
      });
    });
  });
});
