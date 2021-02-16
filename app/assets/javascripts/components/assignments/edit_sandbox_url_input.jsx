import React, { useState } from 'react';

const EditSandboxUrlInput = ({
  submit
}) => {
  const [newUrl, setNewUrl] = useState('');

  const handleUrlChange = (e) => {
    setNewUrl(e.target.value);
  };

  const submitNewUrl = (e) => {
    submit(e, newUrl);
  };

  return (
    <form onSubmit={submitNewUrl}>
      <input
        placeholder={I18n.t('assignments.edit_sandbox_url_placeholder')}
        onSubmit={submitNewUrl}
        onChange={handleUrlChange}
      />
      <button className="button border" type="submit">{I18n.t('assignments.submit')}</button>
    </form>
  );
};

export default EditSandboxUrlInput;
