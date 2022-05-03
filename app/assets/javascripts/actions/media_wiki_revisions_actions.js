import { fetchClassFromRevisions } from '../utils/media_wiki_classes';
import { getWikiMap } from '../utils/revision_utils';
import { fetchReferencesAdded } from '../utils/media_wiki_references_utils';
import { RECEIVE_ASSESSMENTS, RECEIVE_REFERENCES, RECEIVE_REFERENCES_COURSE_SPECIFIC, RECEIVE_ASSESSMENTS_COURSE_SPECIFIC } from '../constants/revisions';

export const fetchRevisionsAndReferences = async (revisions, dispatch, courseSpecific = false) => {
  const wikiMap = getWikiMap(revisions);
  fetchClassFromRevisions(wikiMap).then((assessments) => {
    return dispatch({
      type: courseSpecific ? RECEIVE_ASSESSMENTS_COURSE_SPECIFIC : RECEIVE_ASSESSMENTS,
      data: { assessments }
    });
  });

  fetchReferencesAdded(wikiMap).then((referencesAdded) => {
    dispatch({
      type: courseSpecific ? RECEIVE_REFERENCES_COURSE_SPECIFIC : RECEIVE_REFERENCES,
      data: { referencesAdded }
    });
  });
};
