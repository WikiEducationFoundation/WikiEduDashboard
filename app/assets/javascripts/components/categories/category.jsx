import React from 'react';
import PropTypes from 'prop-types';

const Category = ({ category, remove }) => {
  return (
    <tr>
      <td>{category.name}</td>
      <td>{category.depth}</td>
      <td><button onClick={remove}> - </button></td>
    </tr>
  );
};

export default Category;
