import PropTypes from 'prop-types';

export default {
  article_id: PropTypes.number,
  article_pretty_rating: PropTypes.string,
  article_rating: PropTypes.string,
  article_rating_num: PropTypes.number,
  article_title: PropTypes.string.isRequired,
  article_url: PropTypes.string.isRequired,
  assignment_all_statuses: PropTypes.arrayOf(PropTypes.string).isRequired,
  assignment_id: PropTypes.number.isRequired,
  assignment_status: PropTypes.string.isRequired,
  editors: PropTypes.arrayOf(PropTypes.string),
  id: PropTypes.number.isRequired,
  reviewers: PropTypes.arrayOf(PropTypes.string),
  role: PropTypes.number.isRequired,
  sandboxUrl: PropTypes.string.isRequired,
  user_id: PropTypes.number,
  username: PropTypes.string
};
