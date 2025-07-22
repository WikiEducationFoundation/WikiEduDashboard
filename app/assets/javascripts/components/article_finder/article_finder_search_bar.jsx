import React, { useCallback, useState, useEffect, useRef } from 'react';
import { debounce } from 'lodash';
import { fetchArticleAutocompleteResults } from '../../utils/article_finder_utils';

// Controls Search bar and autocomplete functionality
function ArticleFinderSearchBar({ value, onChange, onSearch, disabled, wiki }) {
  const [suggestions, setSuggestions] = useState([]);
  const [isAutocompleteLoading, setAutocompleteLoading] = useState(false);
  const searchInputRef = useRef(null);

  let searchClass = 'article-finder-search-bar';

  if (suggestions.length > 0) {
    searchClass += ' autocomplete-on';
  }

  // Auto-focus on the search input when component mounts
  useEffect(() => {
    const timer = setTimeout(() => {
      if (searchInputRef.current) {
        searchInputRef.current.focus();
      }
    }, 100);
    return () => clearTimeout(timer);
  }, []);

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
    if (e.key === 'Enter') {
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
        ref={searchInputRef}
      />

      {
        isAutocompleteLoading && <div className="loader"><div className="loading__spinner" /></div>
      }

      <button onClick={searchHandler} disabled={disabled}>
        {I18n.t('article_finder.search')}
      </button>

      <div className="autocomplete">
        {
          suggestions.map((sug) => {
            return <div key={sug} className="autocomplete-item" onClick={() => autoCompleteClickHandler(sug)}> {sug} </div>;
          })
        }
      </div>
    </div>
  );
}

export default ArticleFinderSearchBar;
