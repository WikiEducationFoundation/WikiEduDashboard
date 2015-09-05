json.course do
  json.(@course, :title, :description,
        :start, :end, :school, :term, :subject, :slug)
end
