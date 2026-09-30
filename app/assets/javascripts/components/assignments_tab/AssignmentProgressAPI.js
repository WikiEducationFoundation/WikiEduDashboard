import request, { ensureOk } from '~/app/assets/javascripts/utils/request';

// Class-wide assignment progress for the course's Assignments tab. Without an
// item key: the students, the assignments and a summary per assignment. With
// one: also that assignment's per-student rows.
//
// Course slugs contain slashes; the route matches them, so the slug goes into
// the path unescaped, like the rest of the course SPA's URLs.
export const fetchAssignmentProgress = (courseSlug, itemKey) => {
  const query = itemKey ? `?item=${encodeURIComponent(itemKey)}` : '';
  return request(`/courses/${courseSlug}/assignment_progress.json${query}`)
    .then(response => ensureOk(response, 'Assignment progress request failed'))
    .then(response => response.json());
};

export default fetchAssignmentProgress;
