import React from 'react';

const EditSandboxUrlInput = ({ submit, onChange, value }) => {
  return (
    <form onSubmit={submit}>
      <input
        value={value}
        onChange={onChange}
        onSubmit={submit}
        className="edit_sandbox_url_input"
      />
      <button className="button border" type="submit">
        {I18n.t('assignments.submit')}
      </button>
    </form>
  );
};

export default EditSandboxUrlInput;
