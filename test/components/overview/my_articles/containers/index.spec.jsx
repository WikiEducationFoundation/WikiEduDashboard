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
    const template = {
      course: { home_wiki: { language: 'en', project: 'wikipedia' }, slug: 'course/slug' },
      current_user: {}
    };

    it('displays a message if there are no assignments', () => {
      const store = configureMockStore()({
        assignments: { assignments: [], loading: false },
        wikidataLabels: {}
      });

      const props = {
        ...template,
        current_user: { isStudent: true, username: 'Username' }
      };

      const Container = mount(
        <Provider store={store}>
          <MyArticlesContainer {...props} />
        </Provider>
      );

      // This checks that nothing gets rendered.
      expect(Container.children().length).to.equal(1);
      expect(Container.children().at(0).type()).to.equal(MyArticlesContainer);
    });

    it('does not display for an admin', () => {
      const store = configureMockStore()({
        assignments: { assignments: [], loading: false },
        wikidataLabels: {}
      });

      const props = {
        ...template,
        current_user: { isStudent: false, username: 'Username' }
      };

      const Container = mount(
        <Provider store={store}>
          <MyArticlesContainer {...props} />
        </Provider>
      );

      // This checks that nothing gets rendered.
      expect(Container.children().length).to.equal(1);
      expect(Container.children().at(0).type()).to.equal(MyArticlesContainer);
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
        feedback: {},
        wikidataLabels: {},
        ui: { openKey: true }
      });

      const props = {
        ...template,
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
        expect(Container.find('.my-articles-header').length).to.equal(1);
        expect(Container.find('.my-articles-header').text()).to.include('My Articles');
      });

      it('shows the assignment listing (categories)', () => {
        expect(Container.find('Categories').length).to.equal(1);
        expect(Container.find('Categories').text()).to.include('Articles I\'m updating');
      });

      xit('shows the My Articles section if the student has any', () => {
        expect(Container.find('Heading').length).to.equal(1);
        expect(Container.find('Heading').text()).to.include('Articles I\'m updating');
      });

      xit('shows the assignment title and related links', () => {
        expect(Container.find('.title').text()).to.equal('My Article Title from URL');

        const sandboxUrl = props.assignments[0].sandboxUrl;
        const bibliography = Container.find('BibliographyLink a');
        expect(bibliography.length).to.be.ok;
        expect(bibliography.props().href).to.include(sandboxUrl);
        expect(bibliography.props().href).to.include('Bibliography');

        const sandbox = Container.find('SandboxLink a');
        expect(sandbox.length).to.be.ok;
        expect(sandbox.props().href).to.include(sandboxUrl);
      });

      xit('shows the assignment title and related links', () => {
        expect(Container.find('.title').text()).to.equal('My Article Title from URL');

        const sandboxUrl = props.assignments[0].sandboxUrl;
        const bibliography = Container.find('BibliographyLink a');
        expect(bibliography.length).to.be.ok;
        expect(bibliography.props().href).to.include(sandboxUrl);
        expect(bibliography.props().href).to.include('Bibliography');

        const sandbox = Container.find('SandboxLink a');
        expect(sandbox.length).to.be.ok;
        expect(sandbox.props().href).to.include(sandboxUrl);
      });

      xit('hides the progress tracker on load, shows on state change', () => {
        expect(Container.find('section.flow').props().className).to.include('hidden');

        const nav = Container.find('nav.toggle-wizard');
        nav.props().onClick();
        Container.update();

        expect(Container.find('section.flow').props().className).to.not.include('hidden');
      });

      xit('shows the progress tracker with buttons to move ahead', () => {
        const wizard = Container.find('Wizard');
        wizard.setState({ show: true });
        expect(Container.find('section.flow').props().className).to.not.include('hidden');

        const steps = wizard.find('Step');
        expect(steps.length).to.equal(4);
        expect(steps.at(0).find('.step').props().className).to.include('active');
        expect(steps.at(1).find('.step').props().className).to.not.include('active');

        const buttons = wizard.find('ButtonNavigation');
        expect(buttons.length).to.equal(4);
        // The first step should only have a button to move forward
        // and should be enabled by default.
        expect(buttons.at(0).find('button').length).to.equal(1);
        expect(buttons.at(0).find('button').props().disabled).to.be.false;
        // The second step should have a button to move forward and backwards
        // and should be disabled.
        expect(buttons.at(1).find('button').length).to.equal(2);
        expect(buttons.at(1).find('button').at(0).props().disabled).to.be.true;
      });
    });
  });
});
