import { parseISO } from 'date-fns';

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
