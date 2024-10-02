import '../testHelper';
import { getReferencesAdded } from '../../app/assets/javascripts/utils/revision_utils';

const ORES_OBJECT = {
  1: { // wikidataRevision
    itemquality: { features: { 'feature.len(<datasource.wikidatawiki.revision.references>)': 15 } }
  },
  2: { // wikidataRevisionParent
    itemquality: { features: { 'feature.len(<datasource.wikidatawiki.revision.references>)': 13 } }
  },
  3: { // enwikiRevision
    articlequality: { features: { 'feature.wikitext.revision.ref_tags': 20 } }
  },
  4: { // enwikiRevisionParent
    articlequality: { features: { 'feature.wikitext.revision.ref_tags': 10 } }
  },
  5: { // enwikiRevisionNoORES
    articlequality: { features: { } }
  },
  6: { // frwikiRevision
    articlequality: { features: { 'feature.wikitext.revision.ref_tags': 10 } }
  },
  7: { // frwikiRevisionParent
    articlequality: { features: { 'feature.wikitext.revision.ref_tags': 10 } }
  },
  8: { // enwikiFirstRevisionNoReferences
    articlequality: { features: { 'feature.wikitext.revision.ref_tags': 0 } }
  },
};

const wikidataRevision = { revid: 1, wiki: { project: 'wikidata' }, parentid: 2 };
const wikidataRevisionParent = { revid: 2, wiki: { project: 'wikidata' }, parentid: 5 };
const enwikiRevision = { revid: 3, wiki: { project: 'wikipedia', language: 'en' }, parentid: 4 };
const enwikiRevisionParent = { revid: 4, wiki: { project: 'wikipedia', language: 'en' }, parentid: 0 };
const enwikiRevisionNoORES = { revid: 5, wiki: { project: 'wikipedia', language: 'en' } };
const frwikiRevision = { revid: 6, wiki: { project: 'wikipedia', language: 'fr' }, parentid: 7 };
const enwikiFirstRevisionNoReferences = { revid: 8, wiki: { project: 'wikipedia', language: 'en' }, parentid: 0 };

describe('gets references count for ', () => {
  test('first revision', () => {
    const referencesAdded = getReferencesAdded(ORES_OBJECT, enwikiRevisionParent);
    expect(referencesAdded).toBe(10);
  });
  test('revision with parent', () => {
    const referencesAdded = getReferencesAdded(ORES_OBJECT, enwikiRevision);
    expect(referencesAdded).toBe(10);
  });
  test('revision under wikidata', () => {
    const referencesAdded = getReferencesAdded(ORES_OBJECT, wikidataRevision);
    expect(referencesAdded).toBe(2);
  });
  test('revision with no ORES data', () => {
    const referencesAdded = getReferencesAdded(ORES_OBJECT, enwikiRevisionNoORES);
    expect(referencesAdded).not.toBeDefined();
  });
  test('revision with parent having no ORES data', () => {
    const referencesAdded = getReferencesAdded(ORES_OBJECT, wikidataRevisionParent);
    expect(referencesAdded).not.toBeDefined();
  });
  test('first revision having no references', () => {
    const referencesAdded = getReferencesAdded(ORES_OBJECT, enwikiFirstRevisionNoReferences);
    expect(referencesAdded).toBe(0);
  });
  test('revision which added 0 references', () => {
    const referencesAdded = getReferencesAdded(ORES_OBJECT, frwikiRevision);
    expect(referencesAdded).toBe(0);
  });
});
