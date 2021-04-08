import React from 'react';

const EditSandboxUrlInput = ({
  submit, onChange, value
}) => (
  <form onSubmit={submit}>
    <input
      placeholder={I18n.t('assignments.edit_sandbox_url_placeholder')}
      onSubmit={submit}
      onChange={onChange}
      value={value}
    />
    <button className="button border" type="submit">{I18n.t('assignments.submit')}</button>
  </form>
);

export default EditSandboxUrlInput;
