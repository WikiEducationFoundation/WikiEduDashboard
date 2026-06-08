import { stringify } from 'query-string';
import { toWikiDomain } from './wiki_utils';

// Cap on how many revisions we fetch/plot, to keep the graph (and the wp10
// scoring that follows) bounded. wp10 scoring is one serial LiftWing request
// per revision, so this is the dominant factor in how long the Structural
// Completeness view takes to load.
export const MAX_REVISIONS = 50;

// Fetches up to MAX_REVISIONS of an article's revisions within [start, end],
// most recent first, directly from the MediaWiki API (anonymous CORS via
// origin=*). Returns objects shaped for the graphs:
//   { rev_id, username, date, characters }
// `signal` (from an AbortController) lets the caller cancel an in-flight fetch.
export const fetchArticleRevisions = async ({ article, start, end, signal }) => {
  const domain = toWikiDomain({ language: article.language, project: article.project });
  const base = `https://${domain}/w/api.php`;
  const baseParams = {
    action: 'query',
    prop: 'revisions',
    pageids: article.mw_page_id,
    rvprop: 'ids|user|timestamp|size',
    // rvdir 'older' lists newest first, so rvstart must be later than rvend.
    rvstart: new Date(end).toISOString(),
    rvend: new Date(start).toISOString(),
    rvdir: 'older',
    rvlimit: MAX_REVISIONS,
    format: 'json',
    formatversion: 2,
    origin: '*'
  };

  const revisions = [];
  let continuation = null;
  do {
    const url = `${base}?${stringify({ ...baseParams, ...continuation })}`;
    const response = await fetch(url, { signal });
    const data = await response.json();
    const page = data?.query?.pages?.[0];
    (page?.revisions || []).forEach((rev) => {
      revisions.push({
        rev_id: rev.revid,
        username: rev.user,
        date: rev.timestamp,
        characters: rev.size
      });
    });
    continuation = data.continue || null;
  } while (continuation && revisions.length < MAX_REVISIONS);

  return revisions.slice(0, MAX_REVISIONS);
};

// Fetches the article's state as of the course start: the most recent revision
// at or before `start`. Used to anchor the graph's baseline at course start so
// there's no empty gap before the first in-course edit. Returns { rev_id,
// characters } or null if the article didn't exist yet at the course start.
export const fetchBaselineRevision = async ({ article, start, signal }) => {
  const domain = toWikiDomain({ language: article.language, project: article.project });
  const base = `https://${domain}/w/api.php`;
  const params = {
    action: 'query',
    prop: 'revisions',
    pageids: article.mw_page_id,
    rvprop: 'ids|size',
    rvstart: new Date(start).toISOString(),
    rvdir: 'older',
    rvlimit: 1,
    format: 'json',
    formatversion: 2,
    origin: '*'
  };
  const response = await fetch(`${base}?${stringify(params)}`, { signal });
  const data = await response.json();
  const rev = data?.query?.pages?.[0]?.revisions?.[0];
  return rev ? { rev_id: rev.revid, characters: rev.size } : null;
};
