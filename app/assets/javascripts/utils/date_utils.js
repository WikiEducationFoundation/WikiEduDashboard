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
