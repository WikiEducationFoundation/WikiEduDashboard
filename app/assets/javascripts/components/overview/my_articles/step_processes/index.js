import assignments from './assignments';
import reviews from './reviews';

export default (assignment, course) => {
  return assignment.role === 0 ? assignments(assignment, course) : reviews(assignment);
};
