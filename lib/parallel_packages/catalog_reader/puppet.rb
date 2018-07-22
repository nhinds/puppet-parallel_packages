module ParallelPackages
  module CatalogReader
    # Reads resources from a +Puppet::Resource::Catalog+
    class Puppet
      def initialize(catalog)
        @catalog = catalog
      end

      def resources
        catalog.resources.map { |r| PuppetCatalogResource.new r }
      end

      private

      attr_reader :catalog
    end

    class PuppetCatalogResource < Struct.new :resource
      def dependencies
        # FIXME: does reading the relationship graph here re-break https://tickets.puppetlabs.com/browse/PUP-1963 in puppet >= 4.3?
        # ::Puppet.debug "Get dependencies for #{resource.name}"
        resource.catalog.relationship_graph.direct_dependencies_of(resource).map { |dependency| PuppetCatalogResource.new dependency }
      end

      def type
        resource.type
      end

      # FIXME: more generic method name since this should just be a resource? less generic class?
      def package_name
        # TODO: verify renamed packages
        resource[:name]
      end

      def provider
        resource.provider.class.name
      end

      def parameters
        resource.to_hash
      end
    end
  end
end
