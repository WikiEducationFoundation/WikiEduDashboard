import {
  RECEIVE_WIZARD_BLOCK_CATALOG,
  REQUEST_WIZARD_BLOCK_CATALOG,
  WIZARD_BLOCK_CATALOG_FAILED,
  SANDBOX_MODE_SWITCHED,
  SANDBOX_MODE_SWITCH_FAILED,
  SWITCHING_SANDBOX_MODE,
  API_FAIL
} from '../constants';
import request, { ensureOk } from '../utils/request';
import { fetchCourse } from './course_actions';
import { fetchTimeline } from './timeline_actions';

// The standard blocks the assignment wizard can build, so that an admin can put
// one into a timeline after the fact. Each entry comes back annotated with
// whether it matches how this course was set up (see WizardLogicState for why
// that answer is sometimes 'unknown') and whether its title is already in the
// timeline. Both annotations describe the course as it is right now, so the
// catalog is fetched every time the picker opens rather than cached: a sandbox
// switch, a saved block, or a different course would otherwise leave them stale.
export const fetchWizardBlockCatalog = (courseSlug, wizardId = 'researchwrite') => async (dispatch) => {
  dispatch({ type: REQUEST_WIZARD_BLOCK_CATALOG });
  try {
    const path = `/wizards/${wizardId}/blocks.json?course_id=${encodeURIComponent(courseSlug)}`;
    const response = await request(path);
    await ensureOk(response);
    dispatch({ type: RECEIVE_WIZARD_BLOCK_CATALOG, data: await response.json() });
  } catch (data) {
    // API_FAIL surfaces the error as a notification; the specific failure
    // clears the loading state so the picker does not spin forever.
    dispatch({ type: API_FAIL, data });
    dispatch({ type: WIZARD_BLOCK_CATALOG_FAILED });
  }
};

// Switching sandbox mode rewrites the course flag, the tag and several timeline
// blocks at once, so both the course and the timeline are refetched afterwards
// rather than patched locally. The report is stored with the course slug so
// that it is only ever shown against the course it describes.
export const switchSandboxMode = (courseSlug, noSandboxes) => async (dispatch) => {
  dispatch({ type: SWITCHING_SANDBOX_MODE });
  try {
    const response = await request(`/courses/${courseSlug}/sandbox_mode.json`, {
      method: 'POST',
      body: JSON.stringify({ no_sandboxes: noSandboxes })
    });
    await ensureOk(response);
    const data = await response.json();
    dispatch({ type: SANDBOX_MODE_SWITCHED, data, courseSlug });
    fetchCourse(courseSlug)(dispatch);
    fetchTimeline(courseSlug)(dispatch);
  } catch (data) {
    dispatch({ type: API_FAIL, data });
    dispatch({ type: SANDBOX_MODE_SWITCH_FAILED });
  }
};
