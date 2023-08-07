import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { useDispatch, useSelector } from 'react-redux';
import CategoryList from './category_list.jsx';
import { fetchCategories, addCategory } from '../../actions/category_actions.js';

const CategoryHandler = ({ course, current_user }) => {
  const dispatch = useDispatch();

  const categories = useSelector(state => state.categories.categories);
  const loading = useSelector(state => state.categories.loading);

  useEffect(() => { dispatch(fetchCategories(course.slug)); }, []);

  const editable = current_user.isAdvancedRole;
  return (
    <CategoryList
      course={course}
      categories={categories}
      loading={loading}
      addCategory={payload => dispatch(addCategory(payload))}
      editable={editable}
    />
  );
};

CategoryHandler.propTypes = {
  course: PropTypes.object,
  current_user: PropTypes.object
};

export default (CategoryHandler);
