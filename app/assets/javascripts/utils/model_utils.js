import { sortBy } from 'lodash-es';

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
export const sortByKey = (models, sortKey, previousKey = null, desc = false, absolute = false, refresh = false) => {
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
  const sortFunc = (model) => {
    // this makes string comparisons case insensitive
    if (typeof model[sortKey] === 'string') {
      return model[sortKey].toLowerCase();
    }
    // if the property doesn't exist, we default to 0
    // this prevents the app from crashing if the property doesn't exist
    // this can happen if the user tries to sort by a property whose networked request has not yet returned
    // or has failed
    return model[sortKey] ?? 0;
  };

  // if we're simply refreshing, we don't want to consider the previous key
  const reverse = refresh ? desc : !sameKey !== !desc; // sameKey OR desc is truthy, but not both

  let newModels;
  if (absolute) {
    const sorted = sortBy(models, [o => Math.abs(o[sortKey])]);
    if (reverse) {
      newModels = sorted.reverse();
    } else {
      newModels = sorted;
    }
  } else if (reverse) {
    newModels = sortBy(models, sortFunc).reverse();
  } else {
    newModels = sortBy(models, sortFunc);
  }
  return { newModels, newKey };
};
