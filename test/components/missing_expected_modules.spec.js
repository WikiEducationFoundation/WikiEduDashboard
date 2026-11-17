import '../testHelper';

// jsdom test env lacks TextEncoder/TextDecoder which react-dom needs
const { TextEncoder, TextDecoder } = require('util');

global.TextEncoder = global.TextEncoder || TextEncoder;
global.TextDecoder = global.TextDecoder || TextDecoder;
global.IS_REACT_ACT_ENVIRONMENT = true;

const React = require('react');
const { createRoot } = require('react-dom/client');
const { act } = require('react-dom/test-utils');

const MissingExpectedModules = require('../../app/assets/javascripts/components/overview/missing_expected_modules').default;

const renderComponent = (missingModules) => {
  const container = document.createElement('div');
  document.body.appendChild(container);
  act(() => {
    createRoot(container).render(
      React.createElement(MissingExpectedModules, { missingModules })
    );
  });
  return container;
};

describe('MissingExpectedModules', () => {
  it('renders nothing when no expected modules are missing', () => {
    expect(renderComponent([]).innerHTML).toBe('');
  });

  it('renders nothing when the course data has no list', () => {
    expect(renderComponent(undefined).innerHTML).toBe('');
  });

  it('lists each missing expectation with its alternatives', () => {
    const container = renderComponent([
      ['Plagiarism'],
      ['Moving work out of the sandbox', 'Moving group work live']
    ]);
    const items = [...container.querySelectorAll('li')].map(li => li.textContent);
    expect(items).toEqual([
      'Plagiarism',
      'Moving work out of the sandbox / Moving group work live'
    ]);
  });
});
