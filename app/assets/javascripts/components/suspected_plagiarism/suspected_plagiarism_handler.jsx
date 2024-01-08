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
    // sets the title of this tab
    document.title = `${this.props.course.title} - ${I18n.t('recent_activity.possible_plagiarism')}`;

    if (this.props.loading) {
      this.props.fetchSuspectedCoursePlagiarism(this.props.course_id);
    }
  },

  render() {
    return (
      <div id="possible-plagiarism">
        <div className="section-header">
          <h3 className="article tooltip-trigger">{I18n.t('recent_activity.possible_plagiarism')}
            <span className="tooltip-indicator-heading"/>
            <div className="tooltip dark">
              <p>{I18n.t('recent_activity.plagiarism_explanation')}</p>
            </div>
          </h3>
        </div>
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
