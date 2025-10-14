import React from 'react';

export default ({ currentPage, goToPage, length }) => {
  const pages = Array.from({ length }).map((_el, i) => {
    const className = currentPage === i ? 'selected' : null;
    return (
      <li key={i}>
        <button
          type="button"
          className={className}
          onClick={() => goToPage(i)}
        >
          {i + 1}
        </button>
      </li>
    );
  });

  return (
    <ul className="tickets-pagination">
      { pages }
    </ul>
  );
};
