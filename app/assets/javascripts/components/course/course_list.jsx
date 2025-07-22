import React from 'react';
import List from '../common/list';
import DropdownSortSelect from '../common/dropdown_sort_select';

const CourseList = ({ keys, courses, none_message, sortBy, RowElement, headerText, showSortDropdown }) => {
  const elements = courses.map(course => <RowElement course={course} key={course.slug}/>);
  return (
    <>
      {
        showSortDropdown
        && (
        <div className="section-header">
          <h2>{headerText}</h2>
          <DropdownSortSelect keys={keys} sortSelect={sortBy}/>
        </div>
      )}
      <List keys={keys} elements={elements} none_message={none_message} sortable={true} sortBy={sortBy}/>
    </>
  );
};

export default CourseList;
