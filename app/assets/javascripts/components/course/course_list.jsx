import React from 'react';
import List from '../common/list';
import CourseRow from './course_row';


const CourseList = ({ keys, courses, none_message, sortBy }) => {
  const elements = courses.map(course => <CourseRow course={course} key={course.slug}/>);
  return (
    <List keys={keys} elements={elements} none_message={none_message} sortable={true} sortBy={sortBy}/>
  );
};

export default CourseList;
