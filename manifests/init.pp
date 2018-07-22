class parallel_packages($package_providers = [apt]) {
  parallel_package_generator {parallel_packages:
    package_providers => $package_providers,
  }
}
