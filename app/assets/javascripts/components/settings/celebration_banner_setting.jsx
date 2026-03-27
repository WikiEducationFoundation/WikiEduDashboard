import React, { useEffect, useState } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { getCelebrationBanner, updateCelebrationBanner } from '../../actions/settings_actions';

const CelebrationBannerSetting = () => {
  const dispatch = useDispatch();
  const celebrationBanner = useSelector(state => state.settings.celebrationBanner);

  const [enabled, setEnabled] = useState(false);
  const [visibility, setVisibility] = useState('disabled');
  const [celebrationType, setCelebrationType] = useState('christmas');
  const [customMessage, setCustomMessage] = useState('');
  const [customEmoji, setCustomEmoji] = useState('');
  const [showSnowfall, setShowSnowfall] = useState(true);
  const [autoHideSeconds, setAutoHideSeconds] = useState(7);

  useEffect(() => {
    dispatch(getCelebrationBanner());
  }, [dispatch]);

  useEffect(() => {
    if (celebrationBanner && Object.keys(celebrationBanner).length > 0) {
      setEnabled(celebrationBanner.enabled || false);
      setVisibility(celebrationBanner.visibility || 'disabled');
      setCelebrationType(celebrationBanner.celebration_type || 'christmas');
      setCustomMessage(celebrationBanner.custom_message || '');
      setCustomEmoji((celebrationBanner.custom_emoji || []).join(' '));
      setShowSnowfall(celebrationBanner.show_snowfall !== false);
      setAutoHideSeconds(celebrationBanner.auto_hide_after_seconds || 7);
    }
  }, [celebrationBanner]);

  const handleSave = (e) => {
    e.preventDefault();
    const emojiArray = customEmoji.split(' ').filter(emoji => emoji.trim() !== '');
    const settings = {
      enabled,
      visibility,
      celebration_type: celebrationType,
      custom_message: customMessage,
      custom_emoji: emojiArray,
      show_snowfall: showSnowfall,
      auto_hide_after_seconds: autoHideSeconds
    };
    dispatch(updateCelebrationBanner(settings))
      .catch(() => {
        // Error handling is done by the action
      });
  };

  return (
    <div className="celebration_banner_setting">
      <h2 className="mx2">{I18n.t('settings.celebration_banner.heading')}</h2>
      <div className="mx2">
        <label>
          <input
            type="checkbox"
            checked={enabled}
            onChange={e => setEnabled(e.target.checked)}
          />
          {I18n.t('settings.celebration_banner.enabled')}
        </label>
      </div>

      {enabled && (
        <>
          <div className="mx2 mt2">
            <label>
              {I18n.t('settings.celebration_banner.visibility')}
              <select
                value={visibility}
                onChange={e => setVisibility(e.target.value)}
                className="ml2"
              >
                <option value="disabled">{I18n.t('settings.celebration_banner.visibility_options.disabled')}</option>
                <option value="all_users">{I18n.t('settings.celebration_banner.visibility_options.all_users')}</option>
                <option value="logged_in">{I18n.t('settings.celebration_banner.visibility_options.logged_in')}</option>
                <option value="admins_only">{I18n.t('settings.celebration_banner.visibility_options.admins_only')}</option>
              </select>
            </label>
          </div>

          <div className="mx2 mt2">
            <label>
              {I18n.t('settings.celebration_banner.celebration_type')}
              <select
                value={celebrationType}
                onChange={e => setCelebrationType(e.target.value)}
                className="ml2"
              >
                <option value="christmas">{I18n.t('settings.celebration_banner.celebration_types.christmas')}</option>
                <option value="new_year">{I18n.t('settings.celebration_banner.celebration_types.new_year')}</option>
                <option value="generic">{I18n.t('settings.celebration_banner.celebration_types.generic')}</option>
              </select>
            </label>
          </div>

          <div className="mx2 mt2">
            <label>
              {I18n.t('settings.celebration_banner.custom_message')}
              <input
                type="text"
                value={customMessage}
                onChange={e => setCustomMessage(e.target.value)}
                placeholder={I18n.t('settings.celebration_banner.custom_message_placeholder')}
                className="ml2"
                style={{ width: '400px' }}
              />
            </label>
          </div>

          <div className="mx2 mt2">
            <label>
              {I18n.t('settings.celebration_banner.custom_emoji')}
              <input
                type="text"
                value={customEmoji}
                onChange={e => setCustomEmoji(e.target.value)}
                placeholder="🎄 ✨"
                className="ml2"
                style={{ width: '200px' }}
              />
              <small className="ml2">{I18n.t('settings.celebration_banner.custom_emoji_hint')}</small>
            </label>
          </div>

          <div className="mx2 mt2">
            <label>
              <input
                type="checkbox"
                checked={showSnowfall}
                onChange={e => setShowSnowfall(e.target.checked)}
              />
              {I18n.t('settings.celebration_banner.show_snowfall')}
            </label>
          </div>

          <div className="mx2 mt2">
            <label>
              {I18n.t('settings.celebration_banner.auto_hide_seconds')}
              <input
                type="number"
                value={autoHideSeconds}
                onChange={e => setAutoHideSeconds(parseInt(e.target.value) || 7)}
                min="0"
                max="60"
                className="ml2"
                style={{ width: '80px' }}
              />
            </label>
          </div>
        </>
      )}

      <div className="mx2 mt2">
        <button type="button" className="button dark" onClick={handleSave}>
          {I18n.t('settings.celebration_banner.save_button')}
        </button>
      </div>
    </div>
  );
};

export default CelebrationBannerSetting;


