import React from 'react';
import CookieConsent from 'react-cookie-consent';

const bannerStyle = {
  background: '#40ad90',
  color: 'white',
  fontWeight: '700'
};
const buttonStyle = { borderRadius: '3px',
  background: '#e7e7e7',
  border: '1px solid #e2e2e2',
  color: '#6a6a6a',
  transition: 'all .15s ease-out,color .15s ease-out',
  fontWeight: '400'
};

const ConsentBanner = () => {
  return (
    <CookieConsent location="bottom" containerClasses="consent-banner" buttonStyle={buttonStyle} style={bannerStyle} button_text={I18n.t('application.cookie_consent_acknowledge')}>
      {I18n.t('application.cookie_consent')} <a href="/private_information">{I18n.t('application.cookie_consent_see_more')}</a>
    </CookieConsent>
  );
};

export default ConsentBanner;
