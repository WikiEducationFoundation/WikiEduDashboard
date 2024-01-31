import { getFilteredArticleFinder } from '../../../selectors';
import { useEffect } from 'react';
import { useSelector } from 'react-redux';

const useArticlefinderData = () => {
  const articles = useSelector(state => getFilteredArticleFinder(state));
  const unfilteredArticles = useSelector(
    state => state.articleFinder.articles
  );
  const wikidataLabels = useSelector(state => state.wikidataLabels.labels);
  const loading = useSelector(state => state.articleFinder.loading);
  const search_term = useSelector(state => state.articleFinder.search_term);
  const min_views = useSelector(state => state.articleFinder.min_views);
  const article_quality = useSelector(
    state => state.articleFinder.article_quality
  );
  const search_type = useSelector(state => state.articleFinder.search_type);
  const continue_results = useSelector(
    state => state.articleFinder.continue_results
  );
  const offset = useSelector(state => state.articleFinder.offset);
  const cmcontinue = useSelector(state => state.articleFinder.cmcontinue);
  const assignments = useSelector(state => state.assignments.assignments);
  const loadingAssignments = useSelector(state => state.assignments.loading);
  const fetchState = useSelector(state => state.articleFinder.fetchState);
  const sort = useSelector(state => state.articleFinder.sort);
  const home_wiki = useSelector(state => state.articleFinder.home_wiki);
  const selectedWiki = useSelector(
    state => state.articleFinder.wiki || state.articleFinder.home_wiki
  );

  useEffect(() => {
    // build url if any of the depencency change
    buildURL();
  }, [
    search_term,
    search_type,
    article_quality,
    min_views,
    selectedWiki,
    home_wiki,
  ]);

  const buildURL = (search_value = '') => {
    const itemToSearch = search_value || search_term;
    let queryStringUrl = window.location.href.split('?')[0];
    const params_array = { search_type, article_quality, min_views };
    queryStringUrl += `?search_term=${itemToSearch}`;
    Object.entries(params_array).forEach((param) => {
      const [key, value] = param;
      return (queryStringUrl += `&${key}=${value}`);
    });
    history.replaceState(window.location.href, 'query_string', queryStringUrl);
  };

  return {
    articles,
    unfilteredArticles,
    wikidataLabels,
    loading,
    search_term,
    min_views,
    article_quality,
    search_type,
    continue_results,
    offset,
    cmcontinue,
    assignments,
    loadingAssignments,
    fetchState,
    sort,
    home_wiki,
    selectedWiki,
    buildURL,
  };
};

export default useArticlefinderData;
