require "clusterlb/version"
require 'json'
require 'console_table'
require 'colorize'

module Clusterlb

  class << self
    attr_accessor :config_dir
    attr_accessor :config_file
  end

  self.config_dir = "#{ENV["CLUSTERLB_HOME"]}/configs"
  self.config_file = "#{self.config_dir}/clusterlb.json"

  def list_lbs
    ensure_lb_sites_enabled_dir_exitsts
    config["clusterlb"]["lb_nodes"]
  end

  def config
    envCheck
    writeSampleConfig(config_file) if !File.exists? config_file
    begin
      config = JSON.parse(File.read config_file)
    rescue
      puts "ERROR: Unable to load config file: #{ENV["CLUSTERLB_HOME"]}/configs/clusterlb.json "
      exit 1
    end
  end

  def enable_site(site,node)

    Dir.chdir ENV["CLUSTERLB_HOME"]
    link_to_dir="#{config["clusterlb"]["sites_enabled"]}/#{node}"

    if !config["clusterlb"]["lb_nodes"].include? node
      puts "#{node} is not listed as an active loadballancer, check your configs".colorize(:yellow)
      exit 1
    end

    if !File.directory?(link_to_dir)
      puts "#{link_to_dir} does not exist, check your configs".colorize(:yellow)
      exit 1
    end

    FileUtils.ln_s "../../#{config["clusterlb"]["sites"]}/#{site}", "#{link_to_dir}/#{site}", force: true
    puts "Enableing Site #{site} on #{node}"
  end

  def disable_site(site,node)
    Dir.chdir ENV["CLUSTERLB_HOME"]
    link_dir="#{config["clusterlb"]["sites_enabled"]}/#{node}"
    FileUtils.rm("#{link_dir}/#{site}")
    puts "Disableing Site #{site} on #{node}"
  end

  def matrix_list
    table_config = [{:key=>:site, :size=>35, :title=>"Site"}]
    config["clusterlb"]["lb_nodes"].each do |node|
      table_config.push( {:key=>node.to_sym, :size=>9, :title=>node, :justify=>:center})
    end
    ConsoleTable.define(table_config) do |table|
        Dir.glob("#{ENV["CLUSTERLB_HOME"]}/#{config["clusterlb"]["sites"]}/*").each do |full_path_file|
          filename=full_path_file.split('/')[-1]
          result={:site=>filename}
          config["clusterlb"]["lb_nodes"].each do |node|
            result[node.to_sym]="✓".colorize(:green) if File.exists?("#{ENV["CLUSTERLB_HOME"]}/#{config["clusterlb"]["sites_enabled"]}/#{node}/#{filename}")
          end
          table << result

        end
      end

  end

  private

  def ensure_lb_sites_enabled_dir_exitsts
    [
      "#{ENV["CLUSTERLB_HOME"]}/#{config["clusterlb"]["sites_enabled"]}",
      "#{ENV["CLUSTERLB_HOME"]}/#{config["clusterlb"]["sites"]}"
    ].each do |dir_path|
      FileUtils.mkdir dir_path if !File.directory?(dir_path)
    end
    config["clusterlb"]["lb_nodes"].each do |node|
      node_dir="#{ENV["CLUSTERLB_HOME"]}/#{config["clusterlb"]["sites_enabled"]}/#{node}"
      FileUtils.mkdir node_dir if !File.directory?(node_dir)
    end
  end

  def envCheck
    if ENV["CLUSTERLB_HOME"].nil?
      puts "Please set your ENV 'CLUSTERLB_HOME' to point to the directory where your clusterlb lives"
      exit 1
    end
  end

  def writeSampleConfig(path)
    FileUtils.mkdir config_dir if !File.directory?(config_dir)
    example_config = {
      :clusterlb => {
        :sites => "sites",
        :sites_enabled => "sites-enabled",
        :lb_nodes => ["lb01","lb02","lb03"],
        :nfs_mount => "/srv/clusterlb"
      }
    }
    File.open(path,"w") do |f|
      f.write(JSON.pretty_generate(example_config))
    end
  end



end
