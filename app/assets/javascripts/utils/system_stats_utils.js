export const formatMonthLabel = (monthStr) => {
  if (!monthStr) return '';
  const date = new Date(monthStr);
  if (isNaN(date.getTime())) return monthStr;
  return date.toLocaleDateString(undefined, { month: 'short', year: 'numeric', timeZone: 'UTC' });
};
