import I18n from 'i18n-js';
import React, { useEffect, useRef } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { useSearchParams } from 'react-router-dom';
import { fetchAllCampaigns, sortCampaigns } from '../../actions/campaign_actions';
import List from '../common/list';
import Loading from '../common/loading';

const CampaignList = ({ keys, showSearch, RowElement }) => {
  const { all_campaigns, all_campaigns_loaded, sort } = useSelector(state => state.campaigns);
  const [searchParams, setSearchParams] = useSearchParams();
  const search = searchParams.get('search');
  const filteredCampaigns = search ? all_campaigns.filter(campaign => campaign.title.toLowerCase().includes(search.toLowerCase())) : all_campaigns;
  const dispatch = useDispatch();
  const inputRef = useRef();

  const sortBy = (key) => {
    dispatch(sortCampaigns(key));
  };

  if (sort.key) {
    keys[sort.key].order = (sort.sortKey) ? 'asc' : 'desc';
  }

  const onClickHandler = () => {
    if (inputRef?.current) {
      setSearchParams(`search=${inputRef?.current.value}`);
    }
  };

  useEffect(() => {
    dispatch(fetchAllCampaigns());
  }, []);


  if (!all_campaigns_loaded) {
    return <Loading/>;
  }
  const campaignElements = filteredCampaigns.map(campaign => <RowElement campaign={campaign} key={campaign.slug}/>);

  return (
    <div className="container">
      {
      showSearch && (
        <div className="explore-courses">
          <input type="text" name="name" id="name" placeholder={I18n.t('campaign.search_campaigns')} ref={inputRef}/>
          <button onClick={onClickHandler}><i className="icon icon-search" /></button>
        </div>
        )
      }
      <List
        elements={campaignElements}
        keys={keys}
        none_message={I18n.t('application.no_results', { query: inputRef?.current?.value })}
        sortable={true}
        sortBy={sortBy}
        className="table--expandable table--hoverable"
      />
    </div>
  );
};

export default CampaignList;
