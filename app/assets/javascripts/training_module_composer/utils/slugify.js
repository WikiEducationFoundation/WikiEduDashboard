// Mirror of Rails' String#parameterize for titles entered in the composer UI.
// Lowercases, strips combining diacritical marks (U+0300..U+036F), replaces
// runs of non-alphanumerics with a single hyphen, and trims leading/trailing
// hyphens.
const COMBINING_MARKS = new RegExp('[\\u0300-\\u036f]', 'g');

export const slugifyTitle = (title) => {
  if (!title) return '';
  return title
    .toString()
    .normalize('NFKD')
    .replace(COMBINING_MARKS, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
};

export default slugifyTitle;
