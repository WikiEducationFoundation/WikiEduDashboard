import React from 'react';
import PropTypes from 'prop-types';
import {
  IMPROVING_ARTICLE, NEW_ARTICLE, REVIEWING_ARTICLE
} from '~/app/assets/javascripts/constants/assignments';

// components
import List from './List/List.jsx';

// Helper Functions
const filterStatus = status => ({ article_status }) => status === article_status;
const sortBy = key => (a, b) => (a[key] > b[key] ? 1 : -1);

// Main Component
export const Categories = ({ assignments, course, current_user, wikidataLabels }) => {
  const articles = {
    new: assignments.filter(filterStatus(NEW_ARTICLE)).sort(sortBy('article_title')),
    improving: assignments.filter(filterStatus(IMPROVING_ARTICLE)).sort(sortBy('article_title')),
    reviewing: assignments.filter(filterStatus(REVIEWING_ARTICLE)).sort(sortBy('article_title'))
  };

  const listProps = { course, current_user, wikidataLabels };
  return (
    <>
      {
        articles.new.length
          ? <List {...listProps} assignments={articles.new} title="Articles I will create" />
          : null
      }
      {
        articles.improving.length
          ? <List {...listProps} assignments={articles.improving} title="Articles I'm updating" />
          : null
      }
      {
        articles.reviewing.length
          ? <List {...listProps} assignments={articles.reviewing} title="Articles I'm peer reviewing" />
          : null
      }
    </>
  );
};

Categories.propTypes = {
  // props
  assignments: PropTypes.array.isRequired,
  course: PropTypes.object.isRequired,
  current_user: PropTypes.object.isRequired,
  wikidataLabels: PropTypes.object.isRequired,
};

export default Categories;
