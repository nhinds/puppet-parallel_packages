require 'json'

module ParallelPackages
  module CatalogReader
    # Reads catalogs from the JSON output by +puppet catalog find <agent name>+
    class Json
      def initialize(source)
        @catalog = JSON.load source
      end

      def resources
        catalog['data']['resources'].lazy.map { |r| JsonResource.new(self, r) }
      end

      def dependencies(resource)
        catalog['data']['edges'].select do |edge|
          edge['source'] == resource_name(resource)
        end.map do |edge|
          resources.find do |r|
            edge['target'] == resource_name(r)
          end || fail("Edge from #{edge['source']} to #{edge['target']} exists, but cannot find #{edge['target']} in catalog")
        end.map { |r| JsonResource.new(self, r) }
      end

      private

      attr_reader :catalog

      def resource_name(resource)
        "#{resource['type']}[#{resource['title']}]"
      end
    end

    class JsonResource < Struct.new(:catalog_reader, :resource)
      def dependencies
        catalog_reader.dependencies(self.resource)
      end

      def type
        resource['type']
      end

      # FIXME: more generic method name since this should just be a resource? less generic class?
      def package_name
        # TODO: verify renamed packages
        resource['title']
      end

      def provider
        'TODO' # TODO
      end
    end
  end
end
