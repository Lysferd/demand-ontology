json.array!(@datasets) do |dataset|
  json.extract! dataset, :id, :name, :rdf_source
  json.url dataset_url(dataset, format: :json)
end
