Puppet::Type.newtype(:parallel_package_generator) do
  @doc = "Install packages in parallel."

  # Puppet requires at least one "property" in a type
  ensurable do
    newvalue :present
    defaultto :present
  end

  # Always pretend this resource is already present.
  # This type only exists to generate `parallel_packages` resources and does not manage anything itself.
  def exists?
    true
  end

  newparam(:name)

  newparam(:package_providers) do
    desc 'The package providers to install packages in parallel for'
  end

  def generate
    # Helper classes are only required on agents, so only load them here
    require 'parallel_packages/catalog_traverser'
    require 'parallel_packages/catalog_reader/puppet'

    Puppet.debug 'Generating parallel_packages resources'
    traverser = ParallelPackages::CatalogTraverser.new(ParallelPackages::CatalogReader::Puppet.new(catalog))
    traverser.packages_by_provider.flat_map do |provider, package_sets|
      if package_providers.include? provider
        Puppet.debug "Generating parallel_packages for '#{provider}'"
        package_sets.each_with_index.map do |packages, index|
          parallel_packages_resource(packages, provider, index)
        end.compact
      else
        Puppet.debug "Ignoring packages for provider '#{provider}' which has not been configured as parallel"
        []
      end
    end
  end

  private
  # The package providers to manage, as symbols
  def package_providers
    Array(self[:package_providers]).map(&:to_sym)
  end

  def parallel_packages_resource(packages, provider, index)
    if packages.size > 1
      Puppet.debug "Parallel packages set #{index} for '#{provider}': #{packages}"
      Puppet::Type.type(:parallel_packages).new(name: "#{self[:name]}-#{provider}-#{index}", packages: packages, provider: provider).tap do |parallel_packages|
        package_resources = packages.map { |package| catalog.resource(:package, package) }
        # Ensure parallel packages are installed before the real package resources
        parallel_packages[:before] = package_resources.map(&:ref)
        # Ensure parallel packages are installed after anything the real package resources require
        # FIXME: direct dependencies include "admissible classes" which cannot be used in a metaparam...
        parallel_packages[:require] = package_resources.flat_map { |package| catalog.relationship_graph.direct_dependencies_of(package) }.compact.map(&:ref)
      end
    else
      Puppet.debug "Ignoring package set #{index} for '#{provider}' because it contains only a single package: #{packages}"
      nil
    end
  end
end
