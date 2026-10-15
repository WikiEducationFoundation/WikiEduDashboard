import '../testHelper';

global.IS_REACT_ACT_ENVIRONMENT = true;

jest.mock('../../app/assets/javascripts/utils/article_finder_utils', () => ({
  fetchArticleAutocompleteResults: jest.fn(() => Promise.resolve([]))
}));

const React = require('react');
const { createRoot } = require('react-dom/client');
const { act } = require('react-dom/test-utils');
const { fetchArticleAutocompleteResults } = require('../../app/assets/javascripts/utils/article_finder_utils');
const ArticleFinderSearchBar = require('../../app/assets/javascripts/components/article_finder/article_finder_search_bar').default;

const EN_WIKI = { language: 'en', project: 'wikipedia' };
const FR_WIKI = { language: 'fr', project: 'wikipedia' };

const DEBOUNCE_MS = 500;

// The search bar is a controlled input, so the search term has to be held for
// it the way the Article Finder holds it. Without that React re-renders the
// box with its old value and ignores the next change to it.
const Harness = ({ wiki }) => {
  const [value, setValue] = React.useState('');
  return (
    <ArticleFinderSearchBar
      value={value}
      wiki={wiki}
      onChange={setValue}
      onSearch={() => {}}
      disabled={false}
    />
  );
};

describe('ArticleFinderSearchBar autocomplete', () => {
  let container;
  let root;

  beforeEach(() => {
    jest.useFakeTimers();
    fetchArticleAutocompleteResults.mockReset();
    fetchArticleAutocompleteResults.mockImplementation(() => Promise.resolve([]));
    container = document.createElement('div');
    document.body.appendChild(container);
    act(() => {
      root = createRoot(container);
    });
  });

  afterEach(() => {
    act(() => root.unmount());
    container.remove();
    jest.useRealTimers();
  });

  const render = (wiki) => {
    act(() => {
      root.render(<Harness wiki={wiki} />);
    });
  };

  const enter = (text) => {
    const input = container.querySelector('#article-searchbar');
    const setValue = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value').set;
    act(() => {
      setValue.call(input, text);
      input.dispatchEvent(new window.Event('input', { bubbles: true }));
    });
  };

  const type = async (text) => {
    enter(text);
    await act(async () => {
      jest.advanceTimersByTime(DEBOUNCE_MS + 100);
    });
  };

  const wikisQueried = () => fetchArticleAutocompleteResults.mock.calls.map(([, wiki]) => wiki);
  const suggestionsShown = () => [...container.querySelectorAll('.autocomplete-item')]
    .map(button => button.textContent.trim());

  test('queries the wiki that is selected now, not the one first rendered', async () => {
    render(EN_WIKI);
    await type('par');
    expect(wikisQueried()).toEqual([EN_WIKI]);

    render(FR_WIKI);
    await type('pari');
    expect(wikisQueried()).toEqual([EN_WIKI, FR_WIKI]);
  });

  test('ignores a response that a later request has superseded', async () => {
    let finishFirst;
    fetchArticleAutocompleteResults
      .mockImplementationOnce(() => new Promise((resolve) => { finishFirst = resolve; }))
      .mockImplementationOnce(() => Promise.resolve(['Paris']));

    render(EN_WIKI);
    await type('par');
    await type('paris');

    // The first request finishes last, carrying results for the shorter term.
    await act(async () => {
      finishFirst(['Parrot']);
    });

    expect(suggestionsShown()).toEqual(['Paris']);
  });

  test('drops suggestions still on their way when the box is emptied', async () => {
    render(EN_WIKI);
    enter('par');
    // Empty the box before the debounce has fired.
    enter('');
    await act(async () => {
      jest.advanceTimersByTime(DEBOUNCE_MS + 100);
    });

    expect(fetchArticleAutocompleteResults).not.toHaveBeenCalled();
    expect(suggestionsShown()).toEqual([]);
  });
});
