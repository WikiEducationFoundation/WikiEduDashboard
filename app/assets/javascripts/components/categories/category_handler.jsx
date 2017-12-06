import React from "react";
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from "react-redux";
import CategoryList from "./category_list.jsx";
import { fetchCategories, removeCategory, addCategory } from "../../actions/category_actions.js";

const CategoryHandler = createReactClass({
  displayName: "CategoryHandler",

  propTypes: {
    fetchCategories: PropTypes.func,
    removeCategory: PropTypes.func,
    course: PropTypes.object,
    current_user: PropTypes.object
  },

  componentWillMount() {
    this.props.fetchCategories(this.props.course.slug);
  },

  render() {
    const editable = this.props.current_user.isNonstudent;
    return (
      <CategoryList
        course={this.props.course}
        categories={this.props.categories}
        loading={this.props.loading}
        removeCategory={this.props.removeCategory}
        addCategory={this.props.addCategory}
        editable={editable}
      />
    );
  }
});

const mapStateToProps = state => ({
  categories: state.categories.categories,
  loading: state.categories.loading
});

const mapDispatchToProps = {
  fetchCategories: fetchCategories,
  removeCategory: removeCategory,
  addCategory: addCategory
};

export default connect(mapStateToProps, mapDispatchToProps)(CategoryHandler);
