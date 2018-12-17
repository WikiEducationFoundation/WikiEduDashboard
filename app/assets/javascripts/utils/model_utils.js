import _ from 'lodash';

export const getFiltered = (models, options) => {
  const filteredModels = [];
  for (let i = 0; i < models.length; i += 1) {
    const model = models[i];
    let add = true;
    const iterable1 = Object.keys(options);
    for (let j = 0; j < iterable1.length; j += 1) {
      const criterion = iterable1[j];
      add = add && model[criterion] === options[criterion];
    }
    if (add) { filteredModels.push(model); }
  }
  return filteredModels;
};

// Takes an array of models, the key you want to sort by, the key they are
// already sorted by, and the default sorting direction.
// If you sort a second time by the same key, then it will reverse the sorting.
// Otherwise, it will just sort by that key.
export const sortByKey = (models, sortKey, previousKey = null, desc = false, absolute = false) => {
  const sameKey = sortKey === previousKey;
  let newKey;
  if (sameKey) {
    newKey = null;
  } else {
    newKey = sortKey;
  }

  // Used to sort the models in descending order when some of the values can
  // null. The desired order requires the null values to be in the end instead
  // of beginning.
  function sort(model) {
    if (model[sortKey] === null) {
      return 0;
    }
    return model[sortKey];
  }

  const reverse = !sameKey !== !desc; // sameKey OR desc is truthy, but not both
  let newModels;
  if (absolute) {
    const sorted = _.sortBy(models, [o => Math.abs(o[sortKey])]);
    if (reverse) {
      newModels = sorted.reverse();
    } else {
      newModels = sorted;
    }
  } else if (reverse) {
    newModels = _.sortBy(models, [sort]).reverse();
  } else {
    newModels = _.sortBy(models, sortKey);
  }
  return { newModels, newKey };
};
