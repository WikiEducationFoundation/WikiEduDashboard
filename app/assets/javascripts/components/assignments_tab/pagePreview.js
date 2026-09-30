// Loads a wiki page's rendered HTML straight from the MediaWiki API (CORS), so
// an instructor can read a student's sandbox without leaving the Dashboard.
// The same approach as the Canvas assignment views' sandbox preview
// (app/views/lti_launch/assignment_view.html.haml).

const absolute = (value, origin) => {
  // Fragment-only links (#References) address the preview itself.
  if (!value || value.charAt(0) === '#') { return null; }
  try { return new URL(value, origin).href; } catch (e) { return null; }
};

// The HTML comes from the wiki but is shown on a Dashboard page, so its
// root-relative URLs (/wiki/Foo, thumbnails) would resolve against the
// Dashboard. Rebase them against the wiki, and send links to a new tab.
export const rebaseHtml = (html, origin) => {
  const doc = new DOMParser().parseFromString(`<div>${html}</div>`, 'text/html');
  const root = doc.body.firstChild;
  root.querySelectorAll('a[href]').forEach((link) => {
    const href = absolute(link.getAttribute('href'), origin);
    if (href) { link.setAttribute('href', href); }
    link.setAttribute('target', '_blank');
    link.setAttribute('rel', 'noopener noreferrer');
  });
  root.querySelectorAll('img[src]').forEach((img) => {
    const src = absolute(img.getAttribute('src'), origin);
    if (src) { img.setAttribute('src', src); }
  });
  return root.innerHTML;
};

// Resolves to the page's HTML, or null when the page doesn't exist.
export const fetchPagePreview = (pageUrl) => {
  const url = new URL(pageUrl);
  const title = decodeURIComponent(url.pathname.replace(/^\/wiki\//, ''));
  const api = `${url.origin}/w/api.php?action=parse&prop=text&format=json&formatversion=2`
    + `&disableeditsection=1&redirects=1&origin=*&page=${encodeURIComponent(title)}`;
  return fetch(api)
    .then(response => response.json())
    .then(data => (data.parse?.text ? rebaseHtml(data.parse.text, url.origin) : null));
};
