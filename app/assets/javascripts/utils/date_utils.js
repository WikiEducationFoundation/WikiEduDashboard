import { format, isValid, parseISO } from 'date-fns';

// this exists because unlike moment-js, date-fns doesn't have a generalized toDate function
/**
 * @param  {Date|string} date
*/
export const toDate = (date) => {
  if (date instanceof Date) {
    return date;
  }
  // should not really happen in production, but it's here for making the tests pass
  // this is what moment js does for invalid dates
  if (date === null || date === undefined) {
    return new Date();
  }

  const parsedDate = parseISO(date);
  if (!isValid(parsedDate)) {
    // eslint-disable-next-line no-console
    console.log(`Invalid date - ${date}`);
  }
  return parsedDate;
};

export const formatWithTime = (date) => {
  // example - 2022-07-21 11:02 AM
  return format(toDate(date), 'yyyy-MM-dd p');
};

export const formatWithoutTime = (date) => {
  // example - 2022-07-21
  return format(toDate(date), 'yyyy-MM-dd');
};

// since date-fns is based on the inbuilt Date object(which doesn't carry Timezone information),
// we need this helper to get the date in UTC
// see https://github.com/date-fns/date-fns/issues/376#issuecomment-353871093
// and https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date/toISOString
export const getUTCDateString = (dateString = new Date()) => {
  const date = new Date(dateString);
  return date.toISOString();
};
