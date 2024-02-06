import React from 'react';

const EditSandboxUrlInput = ({ submit, onChange, value }) => {
    return (
      <form onSubmit={submit}>
        <input
          placeholder={I18n.t('assignments.edit_sandbox_url_placeholder')}
          value={value}
          onChange={onChange}
          onSubmit={submit}
        />
        <button className="button border" type="submit">
          {I18n.t('assignments.submit')}
        </button>
      </form>
    );
};

export default EditSandboxUrlInput;
