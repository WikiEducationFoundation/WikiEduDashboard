import { useDispatch, useSelector } from 'react-redux';
import { ARTICLES_PER_PAGE, RESET_PAGES, SET_ARTICLES_PAGE } from '../../constants';
import React from 'react';
import ReactPaginate from 'react-paginate';
import { getPageRange } from '../../utils/article_utils';
import { getArticlesByTrackedStatus } from '../../selectors';

const nextLabel = I18n.t('articles.next');
const previousLabel = I18n.t('articles.previous');

export const PaginatedArticleControls = ({ showMore, limitReached }) => {
  const dispatch = useDispatch();

  const handlePageChange = ({ selected }) => {
    dispatch({ type: SET_ARTICLES_PAGE, page: selected + 1 });
  };

  const totalPages = useSelector(state => state.articles.totalPages);
  const filteredArticles = useSelector(getArticlesByTrackedStatus);
  const currentPage = useSelector(state => state.articles.currentPage);
  const pageRange = getPageRange(currentPage, filteredArticles.length);
  const totalFilteredArticles = Math.min(filteredArticles.length, currentPage * ARTICLES_PER_PAGE);


  // this is for when a filter is applied and the number of pages changes
  // we need to reset the page to the first page
  const computedCurrentPage = Math.ceil(filteredArticles.length / ARTICLES_PER_PAGE);
  if (computedCurrentPage !== totalPages) {
    dispatch({ type: RESET_PAGES, totalPages: computedCurrentPage });
  }


  return (
    <div id="articles-view-controls" className={limitReached ? 'hidden-see-more-btn' : ''}>
      { totalPages ? (<ReactPaginate
        pageCount={totalPages}
        nextLabel={nextLabel}
        previousLabel={previousLabel}
        breakLabel="..."
        containerClassName={'pagination'}
        onPageChange={handlePageChange}
        forcePage={currentPage - 1}
      />) : null }
      {!limitReached
        && (
          <button
            style={{ width: 'max-content', height: 'max-content' }}
            className="button ghost articles-see-more-btn" onClick={showMore}
          >
            {I18n.t('articles.see_more')}
          </button>
        )
      }
      <p className="articles-shown-label">
        { totalPages ? I18n.t('articles.articles_shown', { count: pageRange, total: totalFilteredArticles }) : null}
      </p>
    </div>
  );
};
