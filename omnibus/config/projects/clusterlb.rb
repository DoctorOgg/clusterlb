#
# Copyright 2019 YOUR NAME
#
# All Rights Reserved.
#

name "clusterlb"
maintainer "Dr. Ogg <ogg@sr375.com>"
homepage "https://CHANGE-ME.com"

# Defaults to C:/clusterlb on Windows
# and /opt/clusterlb on all other platforms
install_dir "#{default_root}/#{name}"

build_version Omnibus::BuildVersion.semver
# build_version "0.0.0"

build_iteration 1

# Creates required build directories
dependency "preparation"
dependency "clusterlb-gem"
dependency "oggcert-gem"
dependency "acme.sh"

# clusterlb dependencies/components
# dependency "somedep"

exclude "**/.git"
exclude "**/bundler/git"

package :rpm do
  category "Monitoring"
  vendor vendor
  # if Gem::Version.new(platform_version) >= Gem::Version.new(6)
  #   signing_passphrase gpg_passphrase
  # end
end
