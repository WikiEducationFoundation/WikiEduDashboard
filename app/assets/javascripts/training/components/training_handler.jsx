import React from 'react';
import { useParams } from 'react-router-dom';

const TrainingHandler = ({ setCourseId }) => {
  const { course_id } = useParams();
  setCourseId(course_id);
  return <div />;
};

export default TrainingHandler;
