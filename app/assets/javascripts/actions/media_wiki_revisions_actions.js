import { fetchClassFromRevisions } from '../utils/media_wiki_classes';
import { getWikiMap } from '../utils/revision_utils';
import { fetchReferencesAdded } from '../utils/media_wiki_references_utils';
import { RECEIVE_ASSESSMENTS, RECEIVE_REFERENCES } from '../constants/revisions';

export const fetchRevisionsAndReferences = async (revisions, dispatch) => {
  const wikiMap = getWikiMap(revisions);
  fetchClassFromRevisions(wikiMap).then((assessments) => {
    return dispatch({
      type: RECEIVE_ASSESSMENTS,
      data: { assessments }
    });
  });

  fetchReferencesAdded(wikiMap).then((referencesAdded) => {
    dispatch({
      type: RECEIVE_REFERENCES,
      data: { referencesAdded }
    });
  });
};
