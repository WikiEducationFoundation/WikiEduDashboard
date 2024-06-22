import request from './request';
import logErrorMessage from './log_error_message';

export const createInstructorNotificationAlert = async (courseId, subject, message, bccToSalesforce) => {
  const response = await request('alerts/notify_instructors', {
    method: 'POST',
    body: JSON.stringify({ course_id: courseId, message, subject, bcc_to_salesforce: bccToSalesforce })
  });

  if (!response.ok) {
    logErrorMessage(response);
    const data = await response.text();
    response.responseText = data;
    throw response;
  }
  return response.json();
};
