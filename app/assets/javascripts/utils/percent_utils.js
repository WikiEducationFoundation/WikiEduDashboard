// Formats a percentage sent by the server, which sends null when there's
// nothing to take a percentage of (such as a campaign with no students).
export const percentLabel = (value) => {
  if (value === null || value === undefined || value === '') return '—';
  return `${value}%`;
};
