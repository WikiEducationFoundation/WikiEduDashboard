import React, { useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import CreateNewsDropdown from './create_news_dropdown';
import TextAreaInput from '@components/common/text_area_input.jsx';
import { createNewsContent } from '@actions/news_action';

// Component for creating news content
const CreateNewsPopover = ({ setCreateNews }) => {
  const [isHovered, setIsHovered] = useState(false);
  const [newsCreateDropdown, setNewsCreateDropdown] = useState(false);
  const [disableDropdown, setDisableDropdown] = useState(false);
  const [confirmPost, setConfirmPost] = useState(false);

  const dispatch = useDispatch();
  const newsContent = useSelector(state => state.news.create_news.content);

  // Disable create news dropdown after admin clicks on confirm post news
  const disableOptions = disableDropdown ? 'disable-news' : '';

  // Disable text area input after admin clicks on post news or confirm post news
  const disableTextAreaInput = confirmPost || disableDropdown ? 'disable-text-area-input' : '';

  // Function to handle news posting process
  const postNews = () => {
    setConfirmPost(true);
  };

  // Dropdown options component
  const createNewsDropDownOptions = (
    <CreateNewsDropdown
      setCreateNews={setCreateNews}
      newsId={null}
      postNews={postNews}
      confirmPost={confirmPost}
      setConfirmPost={setConfirmPost}
      setDisableDropdown={setDisableDropdown}
    />
  );

  // Handler to update the news content in the Redux store
  const onChangeCreateNewsContent = (_valueKey, value) => {
    dispatch(createNewsContent(value));
  };

  return (
    <div className="news-section">
      <div
        className="news-content hovered create-news"
        onMouseEnter={() => setIsHovered(true)}
        onMouseLeave={() => setIsHovered(false)}
      >
        {/* Manage pointer events and opacity based on state */}
        <span className={disableTextAreaInput}>
          <TextAreaInput
            id="CreateNews"
            editable={true}
            name="news"
            onChange={onChangeCreateNewsContent}
            placeholder={I18n.t('news.text_area_input.placeholder')}
            value={newsContent}
            value_key="news"
          />
        </span>
        {isHovered && (
          <div className={`dot-circle ${disableOptions}`}>
            <span
              className="icon-edit_news news-edit"
              onClick={() => setNewsCreateDropdown(value => !value)}
            >
              <span className={`${newsCreateDropdown ? 'dot-icon-circle dot-clicked' : ''}`} />
              {newsCreateDropdown && createNewsDropDownOptions}
            </span>
          </div>
        )}
      </div>
      {disableDropdown && <div className="loading__spinner" />}
      {confirmPost && <h1>{I18n.t('news.post_confirmation.title')}<br /> {I18n.t('news.post_confirmation.confirmation')}</h1>}
      <hr />
    </div>
  );
};

export default CreateNewsPopover;
