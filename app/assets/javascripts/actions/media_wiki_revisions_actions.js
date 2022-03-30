import { fetchClassFromRevisions } from '../utils/media_wiki_classes';
import { getWikiMap } from '../utils/revision_utils';
import { fetchReferencesAdded } from '../utils/media_wiki_references_utils';

export const fetchRevisionsAndReferences = async (prevReferences, prevAssessments, revisions, dispatch) => {
  const wikiMap = getWikiMap(revisions);
  fetchClassFromRevisions(prevAssessments, wikiMap).then((assessments) => {
    // eslint-disable-next-line no-console
    console.log('Successfully fetched all page assessment information');
    return dispatch({
      type: 'RECEIVE_ASSESSMENTS',
      data: { assessments }
    });
  });

  fetchReferencesAdded(prevReferences, wikiMap).then((referencesAdded) => {
    // eslint-disable-next-line no-console
    console.log('Successfully fetched all references information');
    dispatch({
      type: 'RECEIVE_REFERENCES',
      data: { referencesAdded }
    });
  });
};
