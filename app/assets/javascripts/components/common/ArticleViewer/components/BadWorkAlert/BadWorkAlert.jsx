import React from 'react';
import PropTypes from 'prop-types';

// Components
import SubmitIssuePanel from '@components/common/ArticleViewer/components/BadWorkAlert/SubmitIssuePanel.jsx';

export class BadWorkAlert extends React.Component {
  constructor(props) {
    super(props);
    this.state = { message: '', isSubmitting: false };

    this.handleChange = this.handleChange.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
  }

  handleChange(_key, message) {
    this.setState({ message });
  }

  handleSubmit(e) {
    e.preventDefault();
    this.props.submitBadWorkAlert(this.state.message);
    this.setState({ isSubmitting: true });
  }

  render() {
    const { isSubmitting, message } = this.state;
    const { alertStatus } = this.props;

    return (
      <section className="article-alert">
        <article className="learn-more">
          <p>{ I18n.t('instructor_view.bad_work.learn_more') }</p>
          <a target="_blank" className="button dark" href="/training/instructors/fixing-bad-articles/instructors-role-in-cleanup">
            {I18n.t('instructor_view.bad_work.learn_more_button')}
          </a>
        </article>
        <SubmitIssuePanel
          alertStatus={alertStatus}
          handleChange={this.handleChange}
          handleSubmit={this.handleSubmit}
          isSubmitting={isSubmitting}
          message={message}
        />
      </section>
    );
  }
}
BadWorkAlert.propTypes = {
  alertStatus: PropTypes.shape({
    created: PropTypes.bool.isRequired
  }).isRequired,
  submitBadWorkAlert: PropTypes.func.isRequired
};

export default BadWorkAlert;
