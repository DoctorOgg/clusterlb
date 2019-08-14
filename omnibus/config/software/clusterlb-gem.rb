name "clusterlb-gem"
default_version "0.1.27"

dependency "ruby"
dependency "ncurses"
dependency "rubygems"

build do
  env = with_standard_compiler_flags(with_embedded_path)
  skip_transitive_dependency_licensing true
  patch_env = env.dup

  # files_dir = "#{project.files_path}/#{name}"

  gem "install clusterlb" \
      " --version '#{version}'" \
      " --bindir '#{install_dir}/embedded/bin'", env: env

  bin_dir = File.join(install_dir, "bin")
  embedded_bin_dir = File.join(install_dir, "embedded", "bin")

  ["clusterlb-nginx", "clusterlb-stectrl", "clusterlb-getcert"].each do |exe|
    link("#{embedded_bin_dir}/#{exe}", "#{bin_dir}/#{exe}")
  end


end
