// Cookie lifetime for remembered collapsed state, in seconds (one year).
const COLLAPSED_COOKIE_MAX_AGE = 60 * 60 * 24 * 365;

// Persists the collapsed state so the server can render the accordion
// already collapsed on the next page load. Clearing = expiring the cookie.
const rememberCollapsedState = (id, collapsed) => {
  const maxAge = collapsed ? COLLAPSED_COOKIE_MAX_AGE : 0;
  document.cookie = `${id}-collapsed=${collapsed ? '1' : ''}; path=/; max-age=${maxAge}; SameSite=Lax`;
};

const toggleAccordian = (id, { remember = false } = {}) => {
  const element = document.getElementById(id);
  const collapsing = element.className.indexOf('collapsed') === -1;
  if (collapsing) {
    element.className = element.className.replace('expanded', 'collapsed');
  } else {
    element.className = element.className.replace('collapsed', 'expanded');
  }
  if (remember) rememberCollapsedState(id, collapsing);
};

window.toggleAccordian = toggleAccordian;
