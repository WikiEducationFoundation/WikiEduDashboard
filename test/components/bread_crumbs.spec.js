import '../testHelper';

const React = require('react');
const { TextEncoder, TextDecoder } = require('util');
global.TextEncoder = global.TextEncoder || TextEncoder;
global.TextDecoder = global.TextDecoder || TextDecoder;
global.IS_REACT_ACT_ENVIRONMENT = true;
const { createRoot } = require('react-dom/client');
const { MemoryRouter, Routes, Route } = require('react-router-dom');
const { act } = require('react');
const BreadCrumbs = require('../../app/assets/javascripts/training/components/bread_crumbs').default;

if (typeof I18n !== 'undefined') {
  I18n.translations = I18n.translations || {};
  I18n.translations.en = I18n.translations.en || {};
  I18n.translations.en.training = I18n.translations.en.training || {};
  I18n.translations.en.training.training_library = 'Training Library';
}

describe('BreadCrumbs', () => {
  let container;
  let reactRoot;

  beforeEach(() => {
    container = document.createElement('div');
    reactRoot = document.createElement('div');

    reactRoot.id = 'react_root';
    reactRoot.setAttribute('data-module-name', 'Test Module');

    document.body.appendChild(reactRoot);
    reactRoot.appendChild(container);
  });

  afterEach(() => {
    document.body.removeChild(reactRoot);
  });

  test('it renders training link', () => {
    act(() => {
      createRoot(container).render(
        React.createElement(BreadCrumbs)
      );
    });

    const link = container.querySelector('li a');

    expect(link).not.toBeNull();
    expect(link.getAttribute('href')).toBe('/training');
    expect(link.textContent).toBe('Training Library');
  });

  test('it renders training module link', () => {
    act(() => {
      createRoot(container).render(
        React.createElement(
          MemoryRouter,
          {
            initialEntries: [
              '/training/students/wikipedia-essentials/five-pillars'
            ]
          },
          React.createElement(
            Routes,
            null,
            React.createElement(
              Route,
              {
                path: '/training/:library_id/:module_id/:any',
                element: React.createElement(BreadCrumbs)
              }
            )
          )
        )
      );
    });

    const links = container.querySelectorAll('li a');
    const moduleLink = links[1];

    expect(moduleLink).not.toBeNull();
    expect(moduleLink.getAttribute('href'))
      .toBe('/training/students/wikipedia-essentials');
    expect(moduleLink.textContent).toBe('Test Module');
  });
});