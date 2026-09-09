// query-string v9 is ESM-only and exposes everything on its default export, with
// no named exports. Re-export the parts we use so call sites can import them by
// name.
import queryString from 'query-string';

export const { parse, stringify } = queryString;
