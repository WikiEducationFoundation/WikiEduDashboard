import React, { useEffect, useRef, useState } from 'react';
import PropTypes from 'prop-types';
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

  const handleChangeCampaign = (values) => {
    if (values.length > 0) {
      setSelectedCampaigns(values);
    } else {
      setSelectedCampaigns([]);
    }
  };

  const openPopover = (e) => {
    if (!isOpen && campaignSelectRef.current) {
      campaignSelectRef.current.focus();
    }
    return open(e);
  };

  const removeCampaignHandler = (campaignId) => {
    dispatch(removeCampaign(course_id, campaignId));
  };

  const addCampaignHandler = () => {
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
  };

  // In editable mode we'll show a list of campaigns and a remove button plus a selector to add new campaigns

  const campaignList = campaigns.map((campaign) => {
    const removeButton = (
      <button className="button border plus" aria-label="Remove campaign" onClick={() => removeCampaignHandler(campaign.title)}>-</button>
    );
    return (
      <tr key={`${campaign.id}_campaign`}>
        <td>{campaign.title}{removeButton}</td>
      </tr>
    );
  });

  let campaignSelect;
  if (availableCampaigns.length > 0) {
    const campaignOptions = availableCampaigns.map((campaign) => {
      return { label: campaign, value: campaign };
    });
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
      <button className="button border plus open" onClick={openPopover}>+</button>
      <Popover
        is_open={isOpen}
        edit_row={campaignSelect}
        rows={campaignList}
      />
    </div>
  );
};

CampaignEditable.propTypes = {
  campaigns: PropTypes.array,
  availableCampaigns: PropTypes.array,
  fetchAllCampaigns: PropTypes.func
};

export default (Conditional(CampaignEditable));
