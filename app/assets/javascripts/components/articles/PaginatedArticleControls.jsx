import { useDispatch, useSelector } from 'react-redux';
import { SET_ARTICLES_PAGE } from '../../constants';
import React from 'react';
import ReactPaginate from 'react-paginate';

export const PaginatedArticleControls = ({ showMore, limitReached }) => {
  const dispatch = useDispatch();

  const handlePageChange = ({ selected }) => {
    dispatch({ type: SET_ARTICLES_PAGE, page: selected + 1 });
  };

  const totalPages = useSelector(state => state.articles.totalPages);

  return (
    <div style={{
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
      paddingBottom: '1em'
    }}
    >
      <ReactPaginate
        pageCount={totalPages}
        nextLabel="Next"
        previousLabel="Previous"
        breakLabel="..."
        containerClassName={'pagination'}
        onPageChange={handlePageChange}
      />
      {
        !limitReached
        && (
          <button
            style={{ width: 'max-content', height: 'max-content' }}
            className="button ghost" onClick={showMore}
          >
            {I18n.t('articles.see_more')}
          </button>
        )
      }
    </div>
  );
};
