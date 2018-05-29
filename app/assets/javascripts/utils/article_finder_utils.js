import logErrorMessage from './log_error_message';

const pageviewBaseUrl = 'https://wikimedia.org/api/rest_v1/metrics/pageviews/per-article/en.wikipedia/all-access/user/';

export const queryUrl = (url, query = {}, dataType = 'jsonp') => {
  return new Promise((res, rej) => {
    return $.ajax({
      dataType: dataType,
      url: url,
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

export const categoryQueryGenerator = (category, namespace) => {
  return {
    list: 'categorymembers',
    cmtitle: category,
    cmlimit: 500,
    cmnamespace: namespace,
    continue: ''
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

export const pageRevisionScoreQueryGenerator = (revids) => {
  return {
    models: 'wp10',
    revids: multipleQueryGenerator(revids)
  };
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

export const extractClassGrade = (pageAssessments) => {
  let classGrade = '';
  _.forEach(pageAssessments, (pageAssessment) => {
    if (pageAssessment.class) {
      classGrade = pageAssessment.class;
      return false;
    }
  });
  return classGrade;
};
