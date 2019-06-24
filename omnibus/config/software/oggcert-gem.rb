name "oggcert-gem"
default_version "0.1.1"

dependency "ruby"
dependency "ncurses"
dependency "rubygems"

build do
  env = with_standard_compiler_flags(with_embedded_path)
  skip_transitive_dependency_licensing true
  patch_env = env.dup


  gem "install oggcert" \
      " --version '#{version}'" \
      " --bindir '#{install_dir}/embedded/bin'", env: env

  bin_dir = File.join(install_dir, "bin")
  embedded_bin_dir = File.join(install_dir, "embedded", "bin")
  link("#{embedded_bin_dir}/oggcert", "#{bin_dir}/oggcert")



end
