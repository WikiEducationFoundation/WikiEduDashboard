import '../testHelper';
import { getLastUpdateMessage, getFirstUpdateMessage, firstUpdateTime, lastSuccessfulUpdateMoment, nextUpdateExpected, getLastUpdateSummary, getTotaUpdatesMessage, getUpdateLogs } from '../../app/assets/javascripts/utils/statistic_update_info_utils';

describe('firstUpdateTime', () => {
  test(
    "calculates first update start time based on time course enqued for update and queue's latency",
    () => {
      const first_update = {
        enqueued_at: '2021-11-28T11:30:22.635Z',
        queue_name: 'short_update',
        queue_latency: 0.1572589874267578
      };
      const result = firstUpdateTime(first_update);
      expect(result).toBeDefined();
    }
  );
});

describe('lastSuccessfulUpdateMoment', () => {
  test(
    'calculates last update time',
    () => {
      const update_logs = {
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
      };

      const result = lastSuccessfulUpdateMoment(update_logs);
      expect(result).toBeDefined();
    }
  );
  test(
    'if no succesfull updates, returns null',
    () => {
      const update_logs = {
        269: {
          start_time: '2021-11-30T14:30:27.230+00:00',
          sentry_tag_uuid: '32eb977b-a233-4006-8eb5-420b9112ce1e',
          error_count: 1
        },
      };
      const result = lastSuccessfulUpdateMoment(update_logs);
      expect(result).toBeNull();
    }
  );
});

describe('getLastUpdateMessage', () => {
  test(
    'returns an array with the last update information',
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
            }
          }
        },
        first_update: {
          enqueued_at: '2021-11-28T11:30:22.635Z',
          queue_name: 'short_update',
          queue_latency: 0.1572589874267578
        },
        updates: {
          average_delay: 1664,
          last_update: {
            start_time: '2021-11-30T21:35:10.631+00:00',
            end_time: '2021-11-30T21:35:11.374+00:00',
            sentry_tag_uuid: 'cbc0fdaa-6232-4231-a07c-4baa53c4bee8',
            error_count: 0
          }
        }
      };

      const result = getLastUpdateMessage(course);
      expect(result).toBeInstanceOf(Array);
    }
  );
  test(
    'if no succesfull updates, it will still return an array',
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

      const result = getLastUpdateMessage(course);
      expect(result).toBeInstanceOf(Array);
    }
  );
});

describe('getFirstUpdateMessage', () => {
  test(
    'returns an array with the first update information',
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

      const result = getFirstUpdateMessage(course);
      expect(result).toBeInstanceOf(Array);
    }
  );
  test(
    'if no first update data, still returns array with that information',
    () => {
      const course = {
        id: 1,
        title: 'My Awesome Course',
        flags: {
          academic_system: null,
          format: ''
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

      const result = getFirstUpdateMessage(course);
      expect(result[0]).toBe("The Dashboard hasn't imported any data for this program yet.");
    }
  );
});
describe('nextUpdateExpected', () => {
  test(
    'returns a time update expected, based on last update data',
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
            }
          }
        },
        first_update: {
          enqueued_at: '2021-11-28T11:30:22.635Z',
          queue_name: 'short_update',
          queue_latency: 0.1572589874267578
        },
        updates: {
          average_delay: 1664,
          last_update: {
            start_time: '2021-11-30T21:35:10.631+00:00',
            end_time: '2021-11-30T21:35:11.374+00:00',
            sentry_tag_uuid: 'cbc0fdaa-6232-4231-a07c-4baa53c4bee8',
            error_count: 0
          }
        }
      };

      const result = nextUpdateExpected(course);
      expect(result).toBeDefined;
    }
  );
  test(
    'if no last update data, returns a time update expected, based on first update info',
    () => {
      const course = {
        id: 1,
        title: 'My Awesome Course',
        flags: {
          academic_system: null,
          format: '',
          first_update: {
            enqueued_at: '2021-11-28T11:30:22.635Z',
            queue_name: 'short_update',
            queue_latency: 0.1572589874267578
          },
        }
      };

      const result = nextUpdateExpected(course);
      expect(result).toBeDefined;
    }
  );
});
describe('getLastUpdateSummary', () => {
  test(
    'returns a last update summary, based on last update data',
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
            }
          }
        },
        first_update: {
          enqueued_at: '2021-11-28T11:30:22.635Z',
          queue_name: 'short_update',
          queue_latency: 0.1572589874267578
        },
        updates: {
          average_delay: 1664,
          last_update: {
            start_time: '2021-11-30T21:35:10.631+00:00',
            end_time: '2021-11-30T21:35:11.374+00:00',
            sentry_tag_uuid: 'cbc0fdaa-6232-4231-a07c-4baa53c4bee8',
            error_count: 0
          }
        }
      };

      const result = getLastUpdateSummary(course);
      expect(result).toBe('The last update ran successfully, so the statistics should be up to date.');
    }
  );
  test(
    'if no last update data, returns a no update summary',
    () => {
      const course = {
        id: 1,
        title: 'My Awesome Course',
        flags: {
          academic_system: null,
          format: '',
          first_update: {
            enqueued_at: '2021-11-28T11:30:22.635Z',
            queue_name: 'short_update',
            queue_latency: 0.1572589874267578
          },
        },
        update_until: '2022-01-12T23:00:00.000Z',
        updated_at: '2021-12-04T14:35:01.000Z',
        updates: { average_delay: null, last_update: null }
      };

      const result = getLastUpdateSummary(course);
      expect(result).toBe("The Dashboard hasn't imported any data for this program yet.");
    }
  );
});

describe('getTotaUpdatesMessage', () => {
  test(
    'returns a total update message, based on last update data',
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
            }
          }
        },
        first_update: {
          enqueued_at: '2021-11-28T11:30:22.635Z',
          queue_name: 'short_update',
          queue_latency: 0.1572589874267578
        },
        updates: {
          average_delay: 1664,
          last_update: {
            start_time: '2021-11-30T21:35:10.631+00:00',
            end_time: '2021-11-30T21:35:11.374+00:00',
            sentry_tag_uuid: 'cbc0fdaa-6232-4231-a07c-4baa53c4bee8',
            error_count: 0
          }
        }
      };

      const result = getTotaUpdatesMessage(course);
      expect(result).toBe('Total number of updates till now: 272.');
    }
  );
  test(
    'if no last update data, returns a no update total message',
    () => {
      const course = {
        id: 1,
        title: 'My Awesome Course',
        flags: {
          academic_system: null,
          format: '',
          first_update: {
            enqueued_at: '2021-11-28T11:30:22.635Z',
            queue_name: 'short_update',
            queue_latency: 0.1572589874267578
          },
        },
        update_until: '2022-01-12T23:00:00.000Z',
        updated_at: '2021-12-04T14:35:01.000Z',
        updates: { average_delay: null, last_update: null }
      };

      const result = getTotaUpdatesMessage(course);
      expect(result).toBe('Total number of updates till now: 0.');
    }
  );
});

describe('getUpdateLogs', () => {
  test(
    'returns an array of update logs, if updates were made',
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
            }
          }
        },
        first_update: {
          enqueued_at: '2021-11-28T11:30:22.635Z',
          queue_name: 'short_update',
          queue_latency: 0.1572589874267578
        },
        updates: {
          average_delay: 1664,
          last_update: {
            start_time: '2021-11-30T21:35:10.631+00:00',
            end_time: '2021-11-30T21:35:11.374+00:00',
            sentry_tag_uuid: 'cbc0fdaa-6232-4231-a07c-4baa53c4bee8',
            error_count: 0
          }
        }
      };

      const result = getUpdateLogs(course);
      expect(result.length).toBe(4);
    }
  );
  test(
    'if no last update data, returns an empty array',
    () => {
      const course = {
        id: 1,
        title: 'My Awesome Course',
        flags: {
          academic_system: null,
          format: '',
          first_update: {
            enqueued_at: '2021-11-28T11:30:22.635Z',
            queue_name: 'short_update',
            queue_latency: 0.1572589874267578
          },
        },
        update_until: '2022-01-12T23:00:00.000Z',
        updated_at: '2021-12-04T14:35:01.000Z',
        updates: { average_delay: null, last_update: null }
      };

      const result = getUpdateLogs(course);
      expect(result.length).toBe(0);
    }
  );
});
