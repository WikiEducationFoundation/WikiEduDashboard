json.training_module do
  json.(@training_module, :slug)
  json.slides @training_module.slides do |slide|
    json.(slide, :title, :summary, :slug, :id, :content, :assessment)
  end
end
