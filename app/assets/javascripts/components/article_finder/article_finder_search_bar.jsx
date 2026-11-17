import React, { useCallback, useMemo, useState, useEffect, useRef } from 'react';
import { debounce } from 'lodash';
import { fetchArticleAutocompleteResults } from '../../utils/article_finder_utils';

// Controls Search bar and autocomplete functionality
function ArticleFinderSearchBar({ value, onChange, onSearch, disabled, wiki }) {
  const [suggestions, setSuggestions] = useState([]);
  const [isAutocompleteLoading, setAutocompleteLoading] = useState(false);
  const searchInputRef = useRef(null);
  // Only the most recent suggestions request may set the suggestions; a slow
  // one must not land after a quicker later one and replace its results.
  const currentRequest = useRef(0);

  // The wiki is read as two values rather than as the object, so that the
  // debounced function below is rebuilt when the user picks a different wiki
  // and not on every render.
  const { language, project } = wiki;

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

  const requestSuggestions = useMemo(() => debounce(async (q) => {
    currentRequest.current += 1;
    const requestNumber = currentRequest.current;

    setAutocompleteLoading(true);
    const results = await fetchArticleAutocompleteResults(q, { language, project })
      .catch(() => []);
    if (currentRequest.current !== requestNumber) { return; }

    setAutocompleteLoading(false);
    setSuggestions(results);
  }, 500), [language, project]);

  // Bumping the request number is what makes a request already in flight
  // discard its own result.
  const discardPendingSuggestions = useCallback(() => {
    requestSuggestions.cancel();
    currentRequest.current += 1;
    setAutocompleteLoading(false);
  }, [requestSuggestions]);

  // Picking a different wiki rebuilds the debounced function, and anything
  // still outstanding at that point belongs to the previous wiki.
  useEffect(() => {
    return () => {
      discardPendingSuggestions();
      setSuggestions([]);
    };
  }, [discardPendingSuggestions]);

  const clearSuggestions = () => {
    discardPendingSuggestions();
    setSuggestions([]);
  };

  const inputChangeHandler = (e) => {
    onChange(e.target.value);
    // autocomplete disabled while disabled (during loading etc.)
    if (!disabled) {
      if (e.target.value === '') {
        clearSuggestions();
      } else {
        requestSuggestions(e.target.value);
      }
    }
  };

  const searchHandler = () => {
    if (disabled || value.trim() === '') return;
    clearSuggestions();
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
    clearSuggestions();
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

      <button type="button" onClick={searchHandler} disabled={disabled}>
        {I18n.t('article_finder.search')}
      </button>

      <div className="autocomplete">
        {
          suggestions.map((sug) => {
            return <button type="button" key={sug} className="autocomplete-item" onClick={() => autoCompleteClickHandler(sug)}> {sug} </button>;
          })
        }
      </div>
    </div>
  );
}

export default ArticleFinderSearchBar;
