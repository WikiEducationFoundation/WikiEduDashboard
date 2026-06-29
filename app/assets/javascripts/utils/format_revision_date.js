// Formats an ISO revision timestamp as a human-readable date for display
// (e.g. "December 14, 2025"), in the active locale. Returns '' for a blank
// timestamp so callers can guard on the result.
const formatRevisionDate = (iso) => {
  if (!iso) { return ''; }
  return new Date(iso).toLocaleDateString(I18n.locale, {
    year: 'numeric', month: 'long', day: 'numeric'
  });
};

export default formatRevisionDate;
