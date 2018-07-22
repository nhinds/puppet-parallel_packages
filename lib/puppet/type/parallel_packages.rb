Puppet::Type.newtype(:parallel_packages) do
  @doc = "Install packages in parallel."

  newparam(:name)
  newproperty(:packages, array_matching: :all) do
    desc 'Packages to install in parallel'

    def insync?(is)
      new_packages = should - is
      if new_packages.size <= 1
        Puppet.debug "Skipping parallel_packages for single package '#{new_packages.first}'" if new_packages.size == 1
        true
      else
        false
      end
    end

    def change_to_s(currentvalue, newvalue)
      "installed #{(newvalue - currentvalue).map { |pkg| "'#{pkg}'" }.join(', ')}"
    end
  end

  # Generated resources do not have autorequire applied to them prior to puppet 4.3: https://tickets.puppetlabs.com/browse/PUP-1963
  # ... so look up the relationships that should exist, and add them ourselves
  def generate
    Puppet.debug "Adding relationships for Parallel_packages[#{self[:name]}]"
    builddepends.each do |relationship|
      Puppet.debug "  #{relationship.ref} (#{relationship.event})"
      catalog.relationship_graph.add_edge(relationship)
    end
    []
  end

  # autorequire(:package) do
  #   Puppet.debug("Normal autorequire for #{self[:name]}")
  #   []
  # end
  #
#   # # Monkey patch puppet to allow arbitrary automatic relationships
#   # # TODO: see if we can do this in some other way via the API
#   # def autorequire(rel_catalog = nil)
#   #   super.tap do |relationships|
#   #     Puppet.debug "Thinking about autorequires for #{self[:name]}"
#       # rel_catalog ||= catalog
#   def add_package_relationships
#     Array(self[:packages]).each do |package|
#       package_resource = catalog.resource(:package, package)
#       # Parallel_packages comes before the packages in its +packages+ property which are already in the catalog
#       catalog.relationship_graph.add_edge(Puppet::Relationship.new(self, package_resource))
#       # Parallel_packages comes after the requirements of the package resources in the catalog
#       package_resource.builddepends
#       # FIXME: damn, RelationshipGraph is technically private, but #relationship_graph is public?
#       catalog.relationship_graph.direct_dependencies_of(package_resource).each do |dependency|
#         Puppet.debug "Adding dependency from package[#{package}] to #{dependency.name}"
#         relationships << Puppet::Relationship.new(dependency, self)
#       end
#     end
# #    end
#   end
end
