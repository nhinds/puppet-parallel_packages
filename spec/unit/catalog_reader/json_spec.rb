require 'parallel_packages/catalog_reader/json'

RSpec.describe ParallelPackages::CatalogReader::Json do
  let(:json_source) { double 'JSON source' }
  let(:catalog) do
    {
      'resources' => [

      ],
      'edges' => [

      ]
    }
  end
  subject(:catalog_reader) { ParallelPackages::CatalogReader::Json.new json_source }

  before do
    allow(JSON).to receive(:load).with(json_source).and_return(catalog)
  end

  # TODO
end
