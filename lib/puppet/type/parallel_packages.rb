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
end
