import assignments from './assignments';
import reviews from './reviews';

export default (assignment) => {
  return assignment.role === 0 ? assignments(assignment) : reviews(assignment);
};
