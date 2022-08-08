import { forEach } from 'lodash-es';
import logErrorMessage from './log_error_message';
import fetchJsonp from 'fetch-jsonp';
import { stringify } from 'query-string';

export const queryUrl = async (url, query = {}) => {
  const hasParams = url.includes('?'); // the url might already have params

  // if the url already has params, we need to add a & to the query string
  // if not, we need to add a ? to the query string
  const queryString = `${hasParams ? '&' : '?'}${stringify(query)}`; // add the query string

  const response = await fetchJsonp(`${url}${queryString}`);
  if (!response.ok) {
    const data = await response.text();
    response.responseText = data;
    logErrorMessage(response);
    throw response;
  }
  return response.json();
};

export const categoryQueryGenerator = (category, cmcontinue, namespace) => {
  return {
    list: 'categorymembers',
    cmtitle: category,
    cmlimit: 50,
    cmnamespace: namespace,
    cmcontinue: cmcontinue
  };
};

export const multipleQueryGenerator = (params) => {
  let query = '';
  params.forEach((param) => {
    query += `${param}|`;
  });
  query = query.substr(0, query.length - 1);
  return query;
};

export const pageAssessmentQueryGenerator = (titles) => {
  return {
    prop: 'pageassessments',
    titles: multipleQueryGenerator(titles),
    palimit: 500
  };
};

export const pageRevisionQueryGenerator = (titles) => {
  return {
    prop: 'revisions',
    titles: multipleQueryGenerator(titles),
    rvprop: 'userid|ids|timestamp'
  };
};

export const pageRevisionScoreQueryGenerator = (revids, project) => {
  return {
    models: `${project === 'wikidata' ? 'itemquality' : 'wp10'}`,
    revids: multipleQueryGenerator(revids)
  };
};

export const keywordQueryGenerator = (keyword, offset) => {
  return {
    list: 'search',
    srsearch: keyword,
    srlimit: 50,
    srinfo: 'totalhits',
    srprop: '',
    sroffset: offset
  };
};

export const pageviewQueryGenerator = (pageids) => {
  return {
    prop: 'pageviews',
    pageids: multipleQueryGenerator(pageids)
  };
};

export const extractClassGrade = (pageAssessments) => {
  let classGrade = '';
  forEach(pageAssessments, (pageAssessment) => {
    if (pageAssessment.class) {
      classGrade = pageAssessment.class;
      return false;
    }
  });
  return classGrade;
};
