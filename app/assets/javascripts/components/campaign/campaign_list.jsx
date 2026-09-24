import React, { useEffect, useRef } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { useSearchParams } from 'react-router-dom';
import ReactPaginate from 'react-paginate';
import { fetchAllCampaigns, fetchCampaignStatistics, sortCampaigns } from '../../actions/campaign_actions';
import List from '../common/list';
import Loading from '../common/loading';
import DropdownSortSelect from '../common/dropdown_sort_select';
import SearchBar from '../common/search_bar';

const CampaignList = ({ keys, showSearch, RowElement, headerText, userOnly, showStatistics = false }) => {
  const { all_campaigns, all_campaigns_loaded, total_pages, sort } = useSelector(state => state.campaigns);
  const [searchParams, setSearchParams] = useSearchParams();
  const search = searchParams.get('search') || '';
  const pageParam = parseInt(searchParams.get('page') || '1');
  const currentPage = pageParam > 0 ? pageParam : 1;
  const dispatch = useDispatch();
  const inputRef = useRef();

  const sortBy = (key) => {
    dispatch(sortCampaigns(key));
  };

  if (sort.key) {
    for (const key of Object.keys(keys)) {
      if (key === sort.key) {
        keys[sort.key].order = (sort.sortKey) ? 'asc' : 'desc';
      } else {
        keys[key].order = undefined;
      }
    }
  }

  const onClickHandler = () => {
    const query = inputRef?.current?.value || '';
    const newParams = {};
    if (query) {
      newParams.search = query;
    }
    newParams.page = 1;
    setSearchParams(newParams);
  };

  const handlePageChange = ({ selected }) => {
    const newPage = selected + 1;
    const newParams = {};
    if (search) {
      newParams.search = search;
    }
    newParams.page = newPage;
    setSearchParams(newParams);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  useEffect(() => {
    if (showStatistics) {
      dispatch(fetchCampaignStatistics(userOnly));
    } else {
      dispatch(fetchAllCampaigns(currentPage, search));
    }
  }, [showStatistics, userOnly, currentPage, search]);

  if (!all_campaigns_loaded) {
    return <Loading/>;
  }

  const filteredCampaigns = showStatistics && showSearch && search
    ? all_campaigns.filter(campaign => campaign.title.toLowerCase().includes(search.toLowerCase()))
    : all_campaigns;

  const campaignElements = filteredCampaigns.map(campaign => <RowElement campaign={campaign} key={campaign.slug}/>);

  return (
    <div className="container">
      {headerText && (
        <div className="section-header">
          <h2>{headerText}</h2>
          <DropdownSortSelect keys={keys} sortSelect={sortBy}/>
        </div>
      )}
      {
      showSearch && (
        <div className="explore-courses" >
          <SearchBar ref={inputRef} onClickHandler={onClickHandler} placeholder={I18n.t('campaign.search_campaigns')} value={search}/>
        </div>
        )
      }
      <List
        elements={campaignElements}
        keys={keys}
        none_message={I18n.t('application.no_results', { query: search || inputRef?.current?.value || ' ' })}
        sortable={true}
        sortBy={sortBy}
        className="table--expandable table--hoverable"
      />
      {!showStatistics && total_pages > 1 && (
        <ReactPaginate
          previousLabel={I18n.t('articles.previous')}
          nextLabel={I18n.t('articles.next')}
          breakLabel="..."
          pageCount={total_pages}
          marginPagesDisplayed={2}
          pageRangeDisplayed={5}
          onPageChange={handlePageChange}
          forcePage={currentPage - 1}
          containerClassName="pagination"
        />
      )}
    </div>
  );
};

export default CampaignList;
