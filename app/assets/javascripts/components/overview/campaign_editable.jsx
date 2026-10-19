import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import Select from 'react-select';

import { getAvailableCampaigns } from '../../selectors';
import selectStyles from '../../styles/select';

import Popover from '../common/popover.jsx';
import Conditional from '../high_order/conditional.jsx';

import { removeCampaign, fetchAllCampaigns, addCampaign } from '../../actions/campaign_actions';
import { fetchUsers } from '../../actions/user_actions';
import useExpandablePopover from '../../hooks/useExpandablePopover';


const CampaignEditable = ({ course_id }) => {
  const availableCampaigns = useSelector(state => getAvailableCampaigns(state));
  const campaigns = useSelector(state => state.campaigns.campaigns);
  const dispatch = useDispatch();

  const [selectedCampaigns, setSelectedCampaigns] = useState([]);
  const campaignSelectRef = useRef(null);

  useEffect(() => { dispatch(fetchAllCampaigns()); }, []);

  const getKey = () => {
    return 'add_campaign';
  };
  const { isOpen, ref, open } = useExpandablePopover(getKey);

  const handleChangeCampaign = useCallback((values) => {
    if (values.length > 0) {
      setSelectedCampaigns(values);
    } else {
      setSelectedCampaigns([]);
    }
  }, []);

  const openPopover = useCallback((e) => {
    if (!isOpen && campaignSelectRef.current) {
      campaignSelectRef.current.focus();
    }
    return open(e);
  }, [isOpen, campaignSelectRef, open]);

  const removeCampaignHandler = useCallback((campaignId) => {
    dispatch(removeCampaign(course_id, campaignId));
  },[dispatch, course_id]);

  const addCampaignHandler = useCallback(() => {
    // After adding the campaign, request users so that any defaults are
    // immediately propagated.

    const addCampaignPromises = [];

    selectedCampaigns.forEach((selectedCampaign) => {
      const promise = dispatch(addCampaign(course_id, selectedCampaign.value));
      addCampaignPromises.push(promise);
    });

    // remove from selected campaigns list if campaign was successfully added
    Promise.all(addCampaignPromises).finally(() => {
      const updatedSelectedCampaigns = selectedCampaigns.filter((selectedCampaign) => {
        let shouldRemove = false;

        campaigns.forEach((campaign) => {
          if (campaign.title === selectedCampaign.value) shouldRemove = true;
        });

        return !shouldRemove;
      });
      setSelectedCampaigns(updatedSelectedCampaigns);
      dispatch(fetchUsers(course_id));
    });
  }, [selectedCampaigns,dispatch,course_id,campaigns]);

  // In editable mode we'll show a list of campaigns and a remove button plus a selector to add new campaigns

  const campaignList = useMemo(()=>{
  campaigns.map((campaign) => {
    const removeButton = (
      <button className="button border plus" aria-label="Remove campaign" onClick={() => removeCampaignHandler(campaign.title)}>-</button>
    );
    return (
      <tr key={`${campaign.id}_campaign`}>
        <td>{campaign.title}{removeButton}</td>
      </tr>
    );
  });
},[campaigns,removeCampaignHandler])
   let campaignSelect;
   const campaignOptions = useMemo(()=>{
    if(!availableCampaigns || availableCampaigns.length === 0) return [];
   return availableCampaigns.map((campaign) => ({
      label: campaign,
      value: campaign
   }))
  },[availableCampaigns])

  if (availableCampaigns.length > 0) {
    let addCampaignButtonDisabled = true;
    if (selectedCampaigns.length > 0) {
      addCampaignButtonDisabled = false;
    }
    campaignSelect = (
      <tr>
        <th>
          <div className="select-with-button">
            <Select
              className="fixed-width"
              ref={campaignSelectRef}
              id='campaign_select'
              inputId='campaign_select'
              name="campaign"
              value={selectedCampaigns}
              placeholder={I18n.t('courses.campaign_select')}
              onChange={handleChangeCampaign}
              options={campaignOptions}
              styles={selectStyles}
              isClearable
              isSearchable
              isMulti={true}
            />
            <button type="submit" className="button dark" disabled={addCampaignButtonDisabled} onClick={addCampaignHandler}>
              Add
            </button>
          </div>
        </th>
      </tr>
    );
  }

  return (
    <div key="campaigns" className="pop__container campaigns open" ref={ref}>
      <button
        className="button border plus open" onClick={openPopover}
        aria-label={I18n.t('courses.add_campaign_aria_label')}
      >+
      </button>
      <Popover
        is_open={isOpen}
        edit_row={campaignSelect}
        rows={campaignList}
      />
    </div>
  );
};

export default (Conditional(CampaignEditable));
