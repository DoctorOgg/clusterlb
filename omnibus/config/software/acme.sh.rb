#https://github.com/Neilpang/acme.sh/releases
# https://github.com/Neilpang/acme.sh/archive/2.8.1.tar.gz
# https://github.com/Neilpang/acme.sh.git


name 'acme.sh'
default_version '2.8.1'
version('2.8.1')     { source git: 'https://github.com/Neilpang/acme.sh.git' }

license 'GPLv3.0'
license_file 'LICENSE.md'

skip_transitive_dependency_licensing true

build do
  copy 'acme.sh', "#{install_dir}/embedded/bin/"
  copy "LICENSE.md", "#{install_dir}/licenses/acme.sh.md"
end
