Puppet::Type.type(:parallel_packages).provide(:apt) do
  desc 'Install packages from apt in parallel'

  # Return +true+ if this provider can install a package with the given parameters
  def self.handles?(parameters)
    unknown_parameters = parameters.reject do |key, _value|
      Puppet::Type.metaparam?(key) || self::IGNORED_PARAMS.include?(key)
    end
    self::DEFAULT_PARAMS.each { |key, value| unknown_parameters.delete key if unknown_parameters[key] == value }
    # We handle :latest the same as :present, and assume the package type can handle updating the package if it needs to
    unknown_parameters.delete :ensure if [:present, :latest].include? unknown_parameters[:ensure]
    Puppet.debug "Not able to install '#{parameters[:name]}' in parallel due to unknown parameters: #{unknown_parameters}" unless unknown_parameters.empty?
    unknown_parameters.empty?
  end

  def packages
    resource[:packages] & apt_installed_packages
  end

  def packages=(desired_packages)
    Puppet.debug "Desired=#{desired_packages}"
    new_packages = desired_packages - packages
    Puppet.debug "New=#{new_packages}"
    package_type = Puppet::Type.type(:package)
    apt_provider = package_type.provider(:apt)
    apt_params = self.class::DEFAULT_PARAMS.merge(name: new_packages, title: resource[:name], ensure: :present)
    Puppet.debug("Installing package with apt via #{apt_params}")
    delegate = apt_provider.new(package_type.hash2resource(apt_params))
    delegate.install
  end

  private
  self::IGNORED_PARAMS = [:name, :provider]
  self::DEFAULT_PARAMS = { configfiles: :keep }

  # TODO: fetch this earlier instead of once per cycle?
  def apt_installed_packages
    @apt_installed_packages ||= Puppet::Type.type(:package).provider(:apt).instances.map(&:name)
  end
end
