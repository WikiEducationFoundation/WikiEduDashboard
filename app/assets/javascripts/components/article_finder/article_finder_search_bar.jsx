import React, { useCallback, useState } from 'react';
import { debounce } from 'lodash';
import { fetchArticleAutocompleteResults } from '../../utils/article_finder_utils';

// Controls Search bar and autocomplete functionality

function ArticleFinderSearchBar({ value, onChange, onSearch, disabled, wiki }) {
  const [suggestions, setSuggestions] = useState([]);
  const [isAutocompleteLoading, setAutocompleteLoading] = useState(false);
  let searchClass = 'search-bar';

  if (suggestions.length > 0) {
    searchClass += ' autocomplete-on';
  }

  const _getSuggestionsApi = useCallback(debounce(async (q) => {
    setAutocompleteLoading(true);
    const results = await fetchArticleAutocompleteResults(q, wiki).catch(() => []);
    setAutocompleteLoading(false);
    setSuggestions(results);
  }, 500), []);

  const inputChangeHandler = (e) => {
    onChange(e.target.value);
    // autocomplete disabled while disabled (during loading etc.)
    if (!disabled) {
      if (e.target.value === '') {
        setSuggestions([]);
      } else {
        _getSuggestionsApi(e.target.value);
      }
    }
  };

  const searchHandler = () => {
    if (disabled || value.trim() === '') return;
    setSuggestions([]);
    onSearch(value);
  };

  const onKeyDownHandler = (e) => {
    // Search on Enter
    if (e.keyCode === 13) {
      searchHandler();
    }
  };

  const autoCompleteClickHandler = (suggestion) => {
    onChange(suggestion);
    // call onSearch directly instead of searchHandler to use the latest suggestion value and not the old state value
    onSearch(suggestion);
    setSuggestions([]);
  };

  return (
    <div className={searchClass}>
      <input
        type="text"
        id="article-searchbar"
        placeholder={I18n.t('article_finder.search_placeholder')}
        onChange={inputChangeHandler}
        value={value}
        onKeyDown={onKeyDownHandler}
      />

      {
        isAutocompleteLoading && <div className="loader"><div className="loading__spinner"/></div>
      }

      <button onClick={searchHandler} disabled={disabled}>
        {I18n.t('article_finder.search')}
      </button>
      <div className="autocomplete">
        {
          suggestions.map((sug, index) => {
            return <div key={`suggestion-${index}`} className="autocomplete-item" onClick={() => autoCompleteClickHandler(sug)}> {sug} </div>;
          })
        }
      </div>
    </div>
  );
}

export default ArticleFinderSearchBar;
