# frozen_string_literal: true

#= Helpers for course views
module UploadsHelper
  def pretty_filename(upload)
    pretty = CGI.unescape(upload.file_name)
    pretty['File:'] = ''
    pretty
  end
end
