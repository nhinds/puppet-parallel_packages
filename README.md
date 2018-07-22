puppet-parallel\_packages
========================

Installs packages in parallel in a Puppet catalog automatically.

Currently only supports Puppet 3 and `apt` packages.

Usage
-----

Declare the `parallel_packages` class somewhere in your catalog:

    class { parallel_packages: }

This module will inspect the completed catalog for packages which can be
installed in parallel and automatically install them at the correct point
during the puppet run.
