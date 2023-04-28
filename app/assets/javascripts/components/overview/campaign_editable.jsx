import React, { useState, useEffect, useRef } from 'react';
import { connect, useDispatch } from 'react-redux';
import PropTypes from 'prop-types';
import Select from 'react-select';

import { getAvailableCampaigns } from '../../selectors';
import selectStyles from '../../styles/select';

// import PopoverExpandable from '../high_order/popover_expandable.jsx';
import Popover from '../common/popover.jsx';
import Conditional from '../high_order/conditional.jsx';

import { removeCampaign, fetchAllCampaigns, addCampaign } from '../../actions/campaign_actions';
import { fetchUsers } from '../../actions/user_actions';

const CampaignEditable = ({ course_id, campaigns, open, is_open, stop }) => {
  const [selectedCampaigns, setSelectedCampaigns] = useState([]);
  console.log(open, is_open, stop);
  const campaignSelectRef = useRef(null);
  const dispatch = useDispatch();

  useEffect(() => {
    dispatch(fetchAllCampaigns());
  }, [fetchAllCampaigns]);

  const handleChangeCampaign = (values) => {
    if (values.length > 0) {
      setSelectedCampaigns(values);
    }
  };

  const openPopover = (e, props) => {
    if (!is_open && campaignSelectRef.current) {
      campaignSelectRef.current.focus();
    }
    return props.open(e);
  };

  openPopover.propTypes = {
    open: PropTypes.func
  };

  const removeCampaignHandler = (campaignId) => {
    removeCampaign(course_id, campaignId);
  };

  const addCampaignHandler = () => {
    // After adding the campaign, request users so that any defaults are
    // immediately propagated.
    const addCampaignPromises = [];

    selectedCampaigns.forEach((selectedCampaign) => {
      const promise = addCampaign(course_id, selectedCampaign.value);
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
      fetchUsers(course_id);
    });
  };

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
  if (getAvailableCampaigns.length > 0) {
    const campaignOptions = getAvailableCampaigns.map((campaign) => {
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
            <div key="campaigns" className="pop__container campaigns open" onClick={stop}>
              <button className="button border plus open" onClick={openPopover}>+</button>
              <Popover
                is_open={is_open}
                edit_row={campaignSelect}
                rows={campaignList}
              />
            </div>
          );
          };

const mapStateToProps = state => ({
  availableCampaigns: getAvailableCampaigns(state),
  campaigns: state.campaigns.campaigns
});

const mapDispatchToProps = {
  removeCampaign,
  addCampaign,
  fetchAllCampaigns,
  fetchUsers
};

export default connect(mapStateToProps, mapDispatchToProps)(
  Conditional(CampaignEditable)
);
