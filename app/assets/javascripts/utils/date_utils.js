import { format, parseISO } from 'date-fns';

// this exists because unlike moment-js, date-fns doesn't have a generalized toDate function
/**
 * @param  {Date|string} date
*/
export const toDate = (date) => {
  if (date instanceof Date) {
    return date;
  }
  return parseISO(date);
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
export const getUTCDate = (dateString = Date.now()) => {
  const date = new Date(dateString);

  return new Date(
    date.getUTCFullYear(),
    date.getUTCMonth(),
    date.getUTCDate(),
    date.getUTCHours(),
    date.getUTCMinutes(),
    date.getUTCSeconds(),
  );
};
