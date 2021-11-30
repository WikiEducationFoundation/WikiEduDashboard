import '../testHelper';
import { firstUpdateTime, lastSuccessfulUpdateTime } from '../../app/assets/javascripts/utils/statistic_update_info_utils';

describe('firstUpdateTime', () => {
  test(
    "calculates first update start time based on time course enqued for update and queue's latency",
    () => {
      const course = {
            id: 1,
            title: 'My Awesome Course',
            flags: {
              academic_system: null,
              format: '',
              first_update: {
                enqueued_at: '2021-11-30T13:30:14.148Z',
                queue_name: 'medium_update',
                queue_latency: 0.3774135112762451
              },
            },
            update_until: '2022-09-29T22:00:00.000Z',
            updates: {
              average_delay: null,
              last_update: null
            },
            survey_notifications: [],
            passcode_required: false,
            passcode: 'omupyzac',
            canUploadSyllabus: true,
      };
      const result = firstUpdateTime(course);
      expect(result).toBeDefined();
    }
  );
});

describe('lastSuccessfulUpdateTime', () => {
  test(
    'calculates last update time',
    () => {
      const course = {
        id: 1,
        title: 'My Awesome Course',
        flags: {
          academic_system: null,
          format: '',
          longest_update: 74,
          update_logs: {
            269: {
              start_time: '2021-11-30T14:30:27.230+00:00',
              end_time: '2021-11-30T14:30:27.817+00:00',
              sentry_tag_uuid: '32eb977b-a233-4006-8eb5-420b9112ce1e',
              error_count: 0
            },
            270: {
              start_time: '2021-11-30T14:35:44.201+00:00',
              end_time: '2021-11-30T14:35:46.187+00:00',
              sentry_tag_uuid: 'fcdf21ea-15e0-43e5-b7a9-78dae72ac768',
              error_count: 0
            },
            271: {
              start_time: '2021-11-30T14:40:21.510+00:00',
              end_time: '2021-11-30T14:40:22.808+00:00',
              sentry_tag_uuid: '2b62adbe-c293-4768-8da8-9eb1e803646b',
              error_count: 0
            },
            272: {
              start_time: '2021-11-30T15:21:19.714+00:00',
              end_time: '2021-11-30T15:22:34.285+00:00',
              sentry_tag_uuid: 'b981dcdb-c716-4f9f-a220-56312c9a7a09',
              error_count: 0
            },
          },
          update_until: '2022-09-29T22:00:00.000Z',
        }
      };

      const result = lastSuccessfulUpdateTime(course);
      expect(result).toBeDefined();
    }
  );
  test(
    'if no succesfull updates, returns null',
    () => {
      const course = {
        id: 1,
        title: 'My Awesome Course',
        flags: {
          academic_system: null,
          format: '',
          longest_update: 74,
          update_logs: {
            269: {
              start_time: '2021-11-30T14:30:27.230+00:00',
              sentry_tag_uuid: '32eb977b-a233-4006-8eb5-420b9112ce1e',
              error_count: 1
            },
          },
          update_until: '2022-09-29T22:00:00.000Z',
        }
      };
      const result = lastSuccessfulUpdateTime(course);
      expect(result).toBeNull();
    }
  );
});
