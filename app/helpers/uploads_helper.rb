# frozen_string_literal: true

#= Helpers for course views
module UploadsHelper
  def pretty_filename(upload)
    pretty = upload.file_name
    pretty['File:'] = ''
    pretty
  end
end
