import logErrorMessage from './log_error_message';

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

export const pageRevisionScoreQueryGenerator = (revids) => {
  return {
    models: 'wp10',
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
  _.forEach(pageAssessments, (pageAssessment) => {
    if (pageAssessment.class) {
      classGrade = pageAssessment.class;
      return false;
    }
  });
  return classGrade;
};
