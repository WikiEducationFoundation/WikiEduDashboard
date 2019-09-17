import React from 'react';
import { mount } from 'enzyme';
import { Provider } from 'react-redux';
import { MemoryRouter } from 'react-router';
import configureMockStore from 'redux-mock-store';

import '../../../testHelper';
import MyAssignmentsList from '../../../../app/assets/javascripts/components/overview/my_articles/my_assignments_list.jsx';

const mockStore = configureMockStore()({});

describe('MyAssignmentsList', () => {
  describe('Features.wikiEd = true', () => {
    Features.wikiEd = true;
    const template = {
      assignments: [],
      course: { home_wiki: { language: 'en', project: 'wikipedia' } },
      current_user: {},
      loading: false,
      wikidataLabels: {}
    };

    it('displays a message if there are no assignments', () => {
      const props = {
        ...template,
        current_user: { isStudent: true }
      };

      const Container = mount(
        <Provider store={mockStore}>
          <MyAssignmentsList {...props} />
        </Provider>
      );

      expect(Container.find('NoAssignmentMessage').length).to.be.ok;
      expect(Container.find('section.no-assignment-message').length).to.be.ok;

      const buttons = Container.find('a.button');
      expect(buttons.length).to.equal(2);
      expect(buttons.at(0).text()).to.equal('How to find an article');
      expect(buttons.at(1).text()).to.equal('Evaluating articles and sources');
    });

    it('does not display for an admin', () => {
      const props = {
        ...template,
        current_user: { isStudent: false }
      };

      const Container = mount(
        <Provider store={mockStore}>
          <MyAssignmentsList {...props} />
        </Provider>
      );

      expect(Container.find('NoAssignmentMessage').length).to.not.be.ok;
    });

    describe('Successfully renders Improving Article', () => {
      const props = {
        ...template,
        current_user: { isStudent: true },
        assignments: [
          {
            article_status: 'improving_article',
            article_title: 'My Article Title',
            article_url: 'https://en.wikipedia.org/wiki/My_Article_Title_from_URL',
            assignment_all_statuses: ['not_yet_started', 'in_progress'],
            assignment_status: 'not_yet_started',
            id: 1,
            sandboxUrl: 'http://sandbox_url',
            username: 'username'
          }
        ]
      };

      const Container = mount(
        <Provider store={mockStore}>
          <MemoryRouter>
            <MyAssignmentsList {...props} />
          </MemoryRouter>
        </Provider>
      );

      it('shows the My Articles section if the student has any', () => {
        expect(Container.find('Heading').length).to.equal(1);
        expect(Container.find('Heading').text()).to.include('Articles I\'m updating');
      });

      it('shows the assignment title and related links', () => {
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

      it('shows the assignment title and related links', () => {
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

      it('hides the progress tracker on load, shows on state change', () => {
        expect(Container.find('section.flow').props().className).to.include('hidden');

        const nav = Container.find('nav.toggle-wizard');
        nav.props().onClick();
        Container.update();

        expect(Container.find('section.flow').props().className).to.not.include('hidden');
      });

      it('shows the progress tracker with buttons to move ahead', () => {
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
