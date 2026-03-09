// Component for viewing and setting course creation settings.
import React from 'react';
import List from '../common/list.jsx';
import UpdateCourseCreationSettings from './views/update_course_creation_settings.jsx';

const CourseCreationSettings = ({ settings }) => {
  const keys = {
    recruiting_term: { label: 'Recruiting term' },
    deadline: { label: 'Deadline' },
    before_deadline_message: { label: 'Message before deadline' },
    after_deadline_message: { label: 'Message after deadline' }
  };

  const settingRow = (
    <tr key="course_creation_settings">
      <td>
        {settings && settings.recruiting_term}
      </td>
      <td>
        {settings && settings.deadline}
      </td>
      <td>
        {settings && settings.before_deadline_message}
      </td>
      <td>
        {settings && settings.after_deadline_message}
      </td>
    </tr>
  );

  return (
    <div className="course-creation-settings">
      <h2 className="mx2">{I18n.t('settings.common_settings_components.headings.course_creation_settings')}</h2>
      <UpdateCourseCreationSettings settings={settings} />
      <List
        elements={[settingRow]}
        keys={keys}
        table_key="course-creation-settings"
      />
    </div>
  );
};

export default CourseCreationSettings;
