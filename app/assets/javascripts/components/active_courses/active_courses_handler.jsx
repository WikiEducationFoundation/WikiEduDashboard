import React from 'react';
import ActiveCourseList from '../course/active_course_list';

const ActiveCoursesHandler = ({ dashboardTitle }) => {
  return (
    <>
      <header className="main-page">
        <div className="header">
          <h1 >{dashboardTitle}</h1>
        </div>
      </header>
      <div id="active_courses">
        <ActiveCourseList defaultCampaignOnly={false}/>
      </div>
    </>
  );
};

export default ActiveCoursesHandler;
