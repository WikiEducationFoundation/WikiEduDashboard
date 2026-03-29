import React, { useEffect, useRef } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { useSearchParams } from 'react-router-dom';
import { fetchAllCampaigns, fetchCampaignStatistics, sortCampaigns } from '../../actions/campaign_actions';
import List from '../common/list';
import Loading from '../common/loading';
import DropdownSortSelect from '../common/dropdown_sort_select';
import SearchBar from '../common/search_bar';

const CampaignList = ({ keys, showSearch, RowElement, headerText, userOnly, showStatistics = false }) => {
  const { all_campaigns, all_campaigns_loaded, sort } = useSelector(state => state.campaigns);
  const [searchParams, setSearchParams] = useSearchParams();
  const [minCourses, setMinCourses] = React.useState(0);
  const [statusFilter, setStatusFilter] = React.useState('all');

  const search = searchParams.get('search');
  let filteredCampaigns = showSearch && search ? all_campaigns.filter(campaign => campaign.title.toLowerCase().includes(search.toLowerCase())) : all_campaigns;

  // Power-user filters
  if (minCourses > 0) {
    filteredCampaigns = filteredCampaigns.filter(c => (c.course_count || 0) >= minCourses);
  }
  if (statusFilter !== 'all') {
    const now = new Date();
    filteredCampaigns = filteredCampaigns.filter((c) => {
      const start = new Date(c.start);
      const end = new Date(c.end);
      if (statusFilter === 'ongoing') return start <= now && end >= now;
      if (statusFilter === 'upcoming') return start > now;
      if (statusFilter === 'finished') return end < now;
      return true;
    });
  }

  const dispatch = useDispatch();
  const inputRef = useRef();

  const sortBy = (key) => {
    dispatch(sortCampaigns(key));
  };

  if (sort.key) {
    // eslint-disable-next-line no-restricted-syntax
    for (const key of Object.keys(keys)) {
      if (key === sort.key) {
        keys[sort.key].order = (sort.sortKey) ? 'asc' : 'desc';
      } else {
        keys[key].order = undefined;
      }
    }
  }

  const onClickHandler = () => {
    if (inputRef?.current) {
      setSearchParams(`search=${inputRef?.current.value}`);
    }
  };

  useEffect(() => {
    if (showStatistics) {
      dispatch(fetchCampaignStatistics(userOnly));
    } else {
      dispatch(fetchAllCampaigns());
    }
  }, []);


  if (!all_campaigns_loaded) {
    return <Loading/>;
  }
  const campaignElements = filteredCampaigns.map(campaign => <RowElement campaign={campaign} key={campaign.slug}/>);

  return (
    <div className="container">
      {headerText && (
        <div className="section-header">
          <h2>{headerText}</h2>
          <div className="campaign-filters">
            <div className="filter-group">
              <label htmlFor="status-filter">{I18n.t('campaign.status')}:</label>
              <select id="status-filter" value={statusFilter} onChange={e => setStatusFilter(e.target.value)}>
                <option value="all">{I18n.t('campaign.all')}</option>
                <option value="ongoing">{I18n.t('campaign.ongoing')}</option>
                <option value="upcoming">{I18n.t('campaign.upcoming')}</option>
                <option value="finished">{I18n.t('campaign.finished')}</option>
              </select>
            </div>
            <div className="filter-group">
              <label htmlFor="min-courses">{I18n.t('campaign.min_courses')}:</label>
              <input
                id="min-courses"
                type="number"
                min="0"
                value={minCourses}
                onChange={e => setMinCourses(parseInt(e.target.value || 0))}
              />
            </div>
          </div>
          <DropdownSortSelect keys={keys} sortSelect={sortBy}/>
        </div>
      )}
      {
      showSearch && (
        <div className="explore-courses" >
          <SearchBar ref={inputRef} onClickHandler={onClickHandler} placeholder={I18n.t('campaign.search_campaigns')}/>
        </div>
        )
      }
      <List
        elements={campaignElements}
        keys={keys}
        none_message={I18n.t('application.no_results', { query: inputRef?.current?.value || ' ' })}
        sortable={true}
        sortBy={sortBy}
        className="table--expandable table--hoverable"
      />
    </div>
  );
};

export default CampaignList;
