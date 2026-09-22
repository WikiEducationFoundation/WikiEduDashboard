import request, { ensureOk } from './request';

export const createInstructorNotificationAlert = async (courseId, subject, message, bccToSalesforce) => {
  const response = await request('alerts/notify_instructors', {
    method: 'POST',
    body: JSON.stringify({ course_id: courseId, message, subject, bcc_to_salesforce: bccToSalesforce })
  });

  await ensureOk(response);
  return response.json();
};
