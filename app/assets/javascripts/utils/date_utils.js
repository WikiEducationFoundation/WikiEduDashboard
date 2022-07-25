// contains some helper functions for date manipulation/formatting
// all functions take in a valid ISO 8601 date string or a Date object

import { format, isValid, parseISO } from 'date-fns';


// this exists because unlike moment-js, date-fns doesn't have a generalized toDate function
/**
 * @param  {Date|string} date
 * @param {boolean} suppressError
*/
export const toDate = (date, suppressError) => {
  if (date instanceof Date) {
    return date;
  }
  // should not really happen in production, but it's here for making the tests pass
  // this is what moment js does for invalid dates
  if (date === null || date === undefined) {
    if (!suppressError) {
      // eslint-disable-next-line no-console
      console.error('date is null or undefined');
    }
    return new Date();
  }

  const parsedDate = parseISO(date);
  if (!isValid(parsedDate)) {
    // eslint-disable-next-line no-console
    console.log(`Invalid date - ${date}`);
  }
  return parsedDate;
};
/**
 * @param  {Date|string} date
 * @returns {string}
 */
export const formatDateWithTime = (date) => {
  // example - 2022-07-21 11:02 AM
  return format(toDate(date), 'yyyy-MM-dd p');
};

/**
 * @param  {Date|string} date
 * @returns {string}
 */
export const formatDateWithoutTime = (date) => {
  // example - 2022-07-21
  return format(toDate(date), 'yyyy-MM-dd');
};

// since date-fns is based on the inbuilt Date object(which doesn't carry Timezone information),
// we need this helper to get the date in UTC
// see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date/toISOString
/**
 * @param  {Date|string} date
 * @returns {string}
 */
export const getUTCDateString = (dateString = new Date()) => {
  const date = new Date(dateString);
  return date.toISOString();
};

// see https://github.com/date-fns/date-fns/issues/376#issuecomment-353871093
// a hack really since the timezone for this is still the local one but the values are in UTC
// as long as we don't use the timezone information we can use this
/**
 * @param  {Date|string} date
 * @returns {Date}
 */
export const getUTCDate = (date) => {
  return new Date(
    date.getUTCFullYear(),
    date.getUTCMonth(),
    date.getUTCDate(),
    date.getUTCHours(),
    date.getUTCMinutes(),
    date.getUTCSeconds(),
  );
};
