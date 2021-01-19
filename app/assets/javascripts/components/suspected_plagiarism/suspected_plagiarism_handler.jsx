import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import {
  fetchSuspectedCoursePlagiarism,
  sortSuspectedPlagiarism
} from '../../actions/suspected_plagiarism_actions';
import SuspectedPlagiarismList from './suspected_plagiarism_list';

  const PossiblePlagiarismHandler = createReactClass({
  displayName: 'PossiblePlagiarismHandler',

  propTypes: {
    course_id: PropTypes.string,
    course: PropTypes.object,
    sort: PropTypes.object,
    suspectedPlagiarism: PropTypes.array,
    loading: PropTypes.bool,
    fetchSuspectedCoursePlagiarism: PropTypes.func,
    sortSuspectedPlagiarism: PropTypes.func,
  },


  componentDidMount() {
    if (this.props.loading) {
      this.props.fetchSuspectedCoursePlagiarism(this.props.course_id);
    }
  },

  render() {
    return (
      <div id="possible-plagiarism">
        <SuspectedPlagiarismList
          revisions={this.props.suspectedPlagiarism}
          course={this.props.course}
          loaded={!this.props.loading}
          sortBy={this.props.sortSuspectedPlagiarism}
          sort={this.props.sort}
        />
      </div>
    );
  }
});

const mapStateToProps = state => ({
  suspectedPlagiarism: state.suspectedPlagiarism.revisions,
  loading: state.suspectedPlagiarism.loading,
  sort: state.suspectedPlagiarism.sort,
});

const mapDispatchToProps = {
  fetchSuspectedCoursePlagiarism,
  sortSuspectedPlagiarism
};

export default connect(mapStateToProps, mapDispatchToProps)(PossiblePlagiarismHandler);
