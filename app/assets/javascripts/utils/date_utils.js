import { parseISO } from 'date-fns';

export const toDate = (date) => {
  if (date instanceof Date) {
    return date;
  }
  return parseISO(date);
};
