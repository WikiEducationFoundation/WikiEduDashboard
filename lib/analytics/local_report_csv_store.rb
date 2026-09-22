# frozen_string_literal: true

#= Keeps report CSVs on the local filesystem, under the public directory, so that
#= they are served as static files by the web server.
class LocalReportCsvStore
  CSV_PATH = '/system/analytics'

  def initialize
    @directory = "public#{CSV_PATH}"
  end

  def exists?(filename)
    File.exist? path_for(filename)
  end

  def write(filename, data)
    FileUtils.mkdir_p @directory
    File.write path_for(filename), data
  end

  def url_for(filename)
    "#{CSV_PATH}/#{filename}"
  end

  def delete(filename)
    File.delete path_for(filename)
  end

  private

  def path_for(filename)
    "#{@directory}/#{filename}"
  end
end
