import logErrorMessage from './log_error_message';

const mediawikiApiBase = 'https://en.wikipedia.org/w/api.php?action=query&format=json';

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

export const categoryQueryGenerator = (category, namespace) => {
  return {
    list: 'categorymembers',
    cmtitle: category,
    cmlimit: 500,
    cmnamespace: namespace,
    continue: ''
  };
};

export const findSubcategories = (category) => {
  const subcatQuery = categoryQueryGenerator(category, 14);
  return queryMediaWiki(subcatQuery)
  .then((data) => {
    return data.query.categorymembers;
  });
};
