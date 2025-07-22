# frozen_string_literal: true
json.category do
  json.merge! @category.attributes
  json.wiki do
    json.merge! @category.wiki.attributes
  end
end
