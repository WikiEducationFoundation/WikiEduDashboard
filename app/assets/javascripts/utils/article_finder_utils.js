import logErrorMessage from './log_error_message';

const mediawikiApiBase = 'https://en.wikipedia.org/w/api.php?action=query&format=json';
const pageviewBaseUrl = 'https://wikimedia.org/api/rest_v1/metrics/pageviews/per-article/en.wikipedia/all-access/user/';
const pageAssesssmentBaseUrl = 'https://en.wikipedia.org/w/api.php?action=query&format=json&prop=pageassessments';

export const queryMediaWiki = (query) => {
  return new Promise((res, rej) => {
    return $.ajax({
      dataType: 'jsonp',
      url: mediawikiApiBase,
      data: query,
      success: (data) => {
        return res(data);
      },
    })
    .fail((obj) => {
      logErrorMessage(obj);
      return rej(obj);
    });
  });
};

export const queryPageAssessment = (query) => {
  return new Promise((res, rej) => {
    return $.ajax({
      dataType: 'jsonp',
      url: pageAssesssmentBaseUrl,
      data: query,
      success: (data) => {
        return res(data);
      },
    })
    .fail((obj) => {
      logErrorMessage(obj);
      return rej(obj);
    });
  });
};

export const queryPageviews = (queryUrl) => {
  return new Promise((res, rej) => {
    return $.ajax({
      dataType: 'json',
      url: queryUrl,
      success: (data) => {
        return res(data);
      },
    })
    .fail((obj) => {
      logErrorMessage(obj);
      return rej(obj);
    });
  });
};

export const categoryQueryGenerator = (category, namespace) => {
  return {
    list: 'categorymembers',
    cmtitle: category,
    cmlimit: 500,
    cmnamespace: namespace,
    continue: ''
  };
};

export const pageAssessmentQueryGenerator = (titles) => {
  let titlesQuery = '';
  titles.forEach((title) => {
    titlesQuery += `${title}|`;
  });
  titlesQuery = titlesQuery.substr(0, titlesQuery.length - 1);
  return { titles: titlesQuery };
};

export const findSubcategories = (category) => {
  const subcatQuery = categoryQueryGenerator(category, 14);
  return queryMediaWiki(subcatQuery)
  .then((data) => {
    return data.query.categorymembers;
  });
};

const formatDate = (date) => {
  const year = date.getUTCFullYear();
  let month = date.getUTCMonth() + 1;
  if (month < 10) {
    month = `0${month}`;
  }
  let day = date.getUTCDate();
  if (day < 10) {
    day = `0${day}`;
  }
  return `${year}${month}${day}`;
};

export const pageviewQueryGenerator = (title) => {
  const startDateString = formatDate(new Date(new Date() - 50 * 24 * 60 * 60 * 1000));
  const endDateString = formatDate(new Date(new Date() - 1 * 24 * 60 * 60 * 1000));
  title = title.replace(/ /g, '_');
  const queryParams = `${title}/daily/${startDateString}00/${endDateString}00`;
  return pageviewBaseUrl + queryParams;
};

