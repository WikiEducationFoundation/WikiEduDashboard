import '../testHelper';

// jsdom test env lacks TextEncoder/TextDecoder which react-dom needs
const { TextEncoder, TextDecoder } = require('util');

global.TextEncoder = global.TextEncoder || TextEncoder;
global.TextDecoder = global.TextDecoder || TextDecoder;
global.IS_REACT_ACT_ENVIRONMENT = true;

const React = require('react');
const { createRoot } = require('react-dom/client');
const { act } = require('react-dom/test-utils');
const { Provider } = require('react-redux');
const { createStore, applyMiddleware } = require('redux');
const thunk = require('redux-thunk').default;
const reducer = require('../../app/assets/javascripts/reducers').default;

jest.mock('../../app/assets/javascripts/utils/request');
const request = require('../../app/assets/javascripts/utils/request');

const TrainingModules = require('../../app/assets/javascripts/components/timeline/TrainingModules/TrainingModules').default;
const { DISCUSSION_KIND, TRAINING_MODULE_KIND } = require('../../app/assets/javascripts/constants');

const discussion = {
  id: 44,
  slug: 'thinking-about-wikipedia-discussion',
  name: 'Thinking about Wikipedia',
  translated_name: 'Thinking about Wikipedia',
  kind: DISCUSSION_KIND,
  due_date: '2026/09/14',
  slide_count: 1
};
const training = {
  id: 1,
  slug: 'wikipedia-essentials',
  name: 'Wikipedia essentials',
  translated_name: 'Wikipedia essentials',
  kind: TRAINING_MODULE_KIND,
  due_date: '2026/09/14',
  slide_count: 10
};

const slide = (slug, title, content) => ({ slug, title, content, translations: {} });

const respondWith = (slides) => {
  request.default.mockResolvedValue({
    ok: true,
    json: () => Promise.resolve({ training_module: { slides } })
  });
};

const flush = async () => {
  for (let i = 0; i < 5; i += 1) {
    await act(async () => { await Promise.resolve(); });
  }
};

let store;
const render = async (modules) => {
  store = createStore(reducer, applyMiddleware(thunk));
  const container = document.createElement('div');
  document.body.appendChild(container);
  await act(async () => {
    createRoot(container).render(
      React.createElement(Provider, { store },
        React.createElement(TrainingModules, {
          block_modules: modules,
          trainingLibrarySlug: 'students'
        }))
    );
  });
  return container;
};

const openModal = async (container) => {
  await act(async () => { container.querySelector('.discussion-module__view').click(); });
  await flush();
};

const dialog = () => document.querySelector('.discussion-modal');

describe('TrainingModules with a discussion module', () => {
  afterEach(async () => {
    jest.clearAllMocks();
    // Close any modal a test left open; it is portaled into the body.
    await act(async () => {
      document.dispatchEvent(new window.KeyboardEvent('keydown', { key: 'Escape' }));
    });
    document.body.innerHTML = '';
  });

  it('shows the discussion as its own panel, with no link to the training pages', async () => {
    const container = await render([discussion]);
    const panel = container.querySelector('.discussion-module');
    expect(panel.querySelector('.discussion-module__kind').textContent).toEqual('Discussion');
    expect(panel.querySelector('.discussion-module__name').textContent).toEqual('Thinking about Wikipedia');
    expect(container.querySelector('a[href*="/training/"]')).toBeNull();
    expect(container.querySelector('table')).toBeNull();
  });

  it('keeps trainings in the table alongside it', async () => {
    const container = await render([training, discussion]);
    expect(container.querySelectorAll('tr.training-module').length).toEqual(1);
    expect(container.querySelector('a[href="/training/students/wikipedia-essentials"]')).not.toBeNull();
    expect(container.querySelectorAll('.discussion-module').length).toEqual(1);
  });

  it('opens the prompts in a modal when View is clicked', async () => {
    respondWith([slide('thinking-about-wikipedia', 'Discussion: Thinking about Wikipedia',
      '* Does it matter who writes Wikipedia?')]);
    const container = await render([discussion]);
    expect(dialog()).toBeNull();

    await openModal(container);

    expect(request.default).toHaveBeenCalledWith(
      '/training_module.json?module_id=thinking-about-wikipedia-discussion'
    );
    expect(dialog().getAttribute('role')).toEqual('dialog');
    expect(dialog().querySelector('h2').textContent).toEqual('Thinking about Wikipedia');
    expect(dialog().querySelector('.markdown li').textContent)
      .toEqual('Does it matter who writes Wikipedia?');
  });

  it('leaves out the title of a lone slide, which repeats the module name', async () => {
    respondWith([slide('thinking-about-wikipedia', 'Discussion: Thinking about Wikipedia', 'Text')]);
    await openModal(await render([discussion]));
    expect(dialog().querySelector('h3')).toBeNull();
  });

  it('titles each slide when there are several', async () => {
    respondWith([
      slide('gaps-in-wikipedia', "Discussion: What's a content gap?", 'Intro'),
      slide('what-is-a-content-gap', 'Questions to consider', '* A question?')
    ]);
    await openModal(await render([discussion]));
    const titles = [...dialog().querySelectorAll('h3')].map(h3 => h3.textContent);
    expect(titles).toEqual(["Discussion: What's a content gap?", 'Questions to consider']);
  });

  it('shows the slide in the current locale when it has a translation', async () => {
    const translated = slide('thinking-about-wikipedia', 'Title', 'English text');
    translated.translations = { en: { title: 'Title', content: 'Translated text' } };
    respondWith([translated]);
    await openModal(await render([discussion]));
    expect(dialog().querySelector('.markdown').textContent).toContain('Translated text');
  });

  it('closes on Escape and returns focus to the View button', async () => {
    respondWith([slide('thinking-about-wikipedia', 'Title', 'Text')]);
    const container = await render([discussion]);
    await openModal(container);
    expect(document.activeElement).toBe(dialog().querySelector('.discussion-modal__close'));

    await act(async () => {
      document.dispatchEvent(new window.KeyboardEvent('keydown', { key: 'Escape' }));
    });

    expect(dialog()).toBeNull();
    expect(document.activeElement).toBe(container.querySelector('.discussion-module__view'));
  });

  it('closes on a click on the backdrop, but not on the panel', async () => {
    respondWith([slide('thinking-about-wikipedia', 'Title', 'Text')]);
    await openModal(await render([discussion]));

    await act(async () => { dialog().querySelector('.discussion-modal__slide').click(); });
    expect(dialog()).not.toBeNull();

    await act(async () => { dialog().click(); });
    expect(dialog()).toBeNull();
  });

  it('closes and reports the error when the module cannot be fetched', async () => {
    // The notifications reducer logs the failure.
    const consoleError = jest.spyOn(console, 'error').mockImplementation(() => {});
    request.default.mockResolvedValue({ ok: false });
    request.ensureOk.mockRejectedValue(new Error('Internal Server Error'));
    await openModal(await render([discussion]));

    expect(dialog()).toBeNull();
    expect(store.getState().notifications[0].message).toEqual('Internal Server Error');
    consoleError.mockRestore();
  });
});
