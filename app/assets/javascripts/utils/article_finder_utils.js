import _ from 'lodash';
import logErrorMessage from './log_error_message';

const mediawikiApiBase = 'https://en.wikipedia.org/w/api.php?action=query&format=json';

const queryMediaWiki = (query) => {
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

const categoryQueryGenerator = (category, namespace) => {
  return {
    list: 'categorymembers',
    cmtitle: category,
    cmlimit: 500,
    cmnamespace: namespace,
    continue: ''
  };
};

export const getDataForCategory = (category, depth, namespace) => {
  const query = categoryQueryGenerator(category, namespace);
  return queryMediaWiki(query)
  .then((data) => {
    return data.query.categorymembers;
  })
  .then((data) => {
    return getDataForSubCategories(category, depth, namespace)
    .then((values) => {
      return _.concat(values, data);
    });
  });
};

const getDataForSubCategories = (category, depth, namespace) => {
  if (depth > 0) {
    depth -= 1;
    return findSubcategories(category)
    .then((subcats) => {
      const subcatPromises = [];
      subcats.forEach((subcat) => {
        subcatPromises.push(getDataForCategory(subcat.title, depth, namespace));
      });
      return Promise.all(subcatPromises);
    })
    .then((values) => {
      return _.flatten(values);
    });
  }
  return new Promise((res) => {
    res([]);
  });
};

const findSubcategories = (category) => {
  const subcatQuery = categoryQueryGenerator(category, 14);
  return queryMediaWiki(subcatQuery)
  .then((data) => {
    return data.query.categorymembers;
  });
};
