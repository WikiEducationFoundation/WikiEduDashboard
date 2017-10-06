import React from "react";
import { connect } from "react-redux";
import ActivityTable from "./activity_table.jsx";
import { fetchDYKArticles } from "../../actions/did_you_know_actions.js";

const DidYouKnowHandler = React.createClass({
  displayName: "DidYouKnowHandler",

  propTypes: {
    fetchDYKArticles: React.PropTypes.func,
    articles: React.PropTypes.array,
    loading: React.PropTypes.bool
  },

  componentWillMount() {
    this.props.fetchDYKArticles();
  },

  setCourseScope(e) {
    const scoped = e.target.checked;
    this.props.fetchDYKArticles({ scoped });
  },

  render() {
    const headers = [
      { title: I18n.t("recent_activity.article_title"), key: "title" },
      {
        title: I18n.t("recent_activity.revision_score"),
        key: "revision_score",
        style: { width: 142 }
      },
      {
        title: I18n.t("recent_activity.revision_author"),
        key: "username",
        style: { minWidth: 142 }
      },
      {
        title: I18n.t("recent_activity.revision_datetime"),
        key: "revision_datetime",
        style: { width: 200 }
      }
    ];

    const noActivityMessage = I18n.t("recent_activity.no_dyk_eligible");

    return (
      <div>
        <label>
          <input
            ref="myCourses"
            type="checkbox"
            onChange={this.setCourseScope}
          />
          {I18n.t("recent_activity.show_courses")}
        </label>
        <ActivityTable
          loading={this.props.loading}
          activity={this.props.articles}
          headers={headers}
          noActivityMessage={noActivityMessage}
        />
      </div>
    );
  }
});

const mapStateToProps = state => ({
  articles: state.didYouKnow.articles,
  // loading: state.didYouKnowStore.loading
});

const mapDispatchToProps = {
  fetchDYKArticles: fetchDYKArticles
};

export default connect(mapStateToProps, mapDispatchToProps)(DidYouKnowHandler);
