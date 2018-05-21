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

export const titlesQueryGenerator = (titles) => {
  let titlesQuery = '';
  titles.forEach((title) => {
    titlesQuery += `${title}|`;
  });
  titlesQuery = titlesQuery.substr(0, titlesQuery.length - 1);
  return titlesQuery;
};

export const pageAssessmentQueryGenerator = (titles) => {
  return {
    prop: 'pageassessments',
    titles: titlesQueryGenerator(titles)
  };
};

export const pageRevisionQueryGenerator = (titles) => {
  return {
    prop: 'revisions',
    titles: titlesQueryGenerator(titles),
    rvprop: 'userid|ids|timestamp'
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
