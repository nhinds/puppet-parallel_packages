module ParallelPackages
  class CatalogTraverser
    # Construct a new +CatalogTraverser+
    # Params:
    # * catalog_reader - an object which responds to +#resources+ and +#dependencies(resource)+
    def initialize(catalog_reader)
      @catalog_reader = catalog_reader
      @packages = {}
      traverse!
    end

    # Method for enumerating collections of packages which can be installed together
    def packages_by_provider
      Puppet.debug "Calculating packages by provider from packages: #{packages.keys}"
      seen_packages = []
      package_sets = {}
      iterations = 0
      until (packages.keys - seen_packages).empty?
        if (iterations += 1) > 50
          Puppet.warning "More than 50 iterations of package dependencies parsed. This is either a very complex catalog or a bug in parallel_packages. Unhandled packages: #{packages.keys - seen_packages}"
          break
        end
        package_set = packages.reject { |name, _package| seen_packages.include? name }.select { |_name, package| (package[:dependencies] - seen_packages).empty? }
        seen_packages += package_set.keys
        package_set.group_by { |_name, package| package[:resource].provider }.each do |provider, packages|
          # FIXME: this is hooking everything together way too tightly
          unless parallel_provider = Puppet::Type.type(:parallel_packages).provider(provider)
            Puppet.debug "Ignoring packages for package provider '#{provider}' which does not have a parallel_packages provider: #{packages.map { |name, _package| name }}"
            next
          end

          supported_packages = packages.select do |_name, package|
            parallel_provider.handles? package[:resource].parameters
          end
          (package_sets[provider] ||= []) << supported_packages.map { |name, _package| name } unless supported_packages.empty?
        end
      end
      package_sets
    end

    private

    attr_reader :catalog_reader, :packages

    def traverse!
      catalog_reader.resources.select { |r| is_package(r) }.each do |package|
        packages[package.package_name] = {
          resource: package,
          dependencies: package_dependencies(package)
        }
        Puppet.debug "Handling package '#{package.package_name}', dependencies: #{packages[package.package_name][:dependencies]}"
      end
    end

    def is_package(resource)
      resource.type == :package
    end

    def package_dependencies(resource)
      resource.dependencies.flat_map do |dependency|
        if is_package(dependency)
          dependency.package_name
        else
          package_dependencies(dependency)
        end
      end.uniq
    end
  end
end
