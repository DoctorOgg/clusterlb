require "clusterlb/version"
require 'json'
require 'console_table'
require 'colorize'
require 'inifile'
require 'aws-sdk'
require 'fileutils'
require 'net/ssh'



module Clusterlb

  class << self
    attr_accessor :config_dir
    attr_accessor :config_file
  end

  self.config_dir = "#{ENV["CLUSTERLB_HOME"]}/configs"
  self.config_file = "#{self.config_dir}/clusterlb.json"

  def list_lbs
    ensure_dir_exitsts
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



  def cmd_nginx(cmd,node) # test | reload | restart | stop | start ,  lb01 or "all"
    allowed_commands=["test","reload","restart","stop","start"]
    hosts=[]
    if !allowed_commands.include? cmd
      puts "command not in the allowed list: #{allowed_commands.join(',')}".colorize(:red)
      exit 1
    end
    if node == "all"
      list_lbs.each do |h|
        hosts.push "#{h}.#{config["clusterlb"]["lb_nodes_dns_postfix"]}"
      end
    else
      hosts.push "#{node}.#{config["clusterlb"]["lb_nodes_dns_postfix"]}"
    end

    hosts.each do |h|
      puts "h:".colorize(:light_blue)
      go_ssh(h,"sudo /etc/init.d/nginx #{cmd}",ENV['USER'])
      puts "--\n".colorize(:light_blue)
    end
  end

  def aws_config
    aws_config_file="#{ENV["HOME"]}/.aws/credentials"
    if !File.exists? aws_config_file
      puts "Please configure your AWS credentials in #{ENV["HOME"]}/.aws/credentials, and setup profile with the name of #{config["aws"]["profile"]}"
      exit 1
    end
    awsconfig = IniFile.load(aws_config_file)[config["aws"]["profile"]]
    if awsconfig.empty?
      puts "It looks like you're  #{ENV["HOME"]}/.aws/credentials file has no section configured for #{config["aws"]["profile"]} profile. Please Fix this."
      exit 1
    end
    Aws.config.update({
      region: config["aws"]["region"],
      credentials: Aws::Credentials.new(awsconfig['aws_access_key_id'],  awsconfig['aws_secret_access_key'])
    })
  end

  def get_s3_cert(fqdn)

    ensure_dir_exitsts
    aws_config
    certs_dir="#{ENV["CLUSTERLB_HOME"]}/#{config["clusterlb"]["certificates_dir"]}"
    Dir.chdir certs_dir

    s3 = Aws::S3::Client.new
    resp = s3.list_objects_v2({
      bucket: config["aws"]["ssl_cert_bucket"],
      prefix: fqdn
    })
    date_list=[]

    if resp["contents"].length <= 0
      puts "Sorry, i found no Certificates with that prefix #{fqdn}"
      exit 1
    end

    resp["contents"].each do |k|
      date_list.push(DateTime.strptime(k["key"].match('\d{1,2}-\d{1,2}-\d{4}').to_s, "%m-%d-%Y"))
    end

    file_extensions=["full.pem","key","pem","ca.pem"]
    newest_cert_date_string = date_list.sort.reverse.first.strftime("%-m-%-d-%Y")

    file_extensions.each do |ext|
      filename="#{fqdn}.#{newest_cert_date_string}.#{ext}"
      puts "Getting: #{filename} "
      sourceObj = Aws::S3::Object.new(config["aws"]["ssl_cert_bucket"], "#{filename}")
      sourceObj.get(response_target: "#{certs_dir}/#{filename}") if !File.exists? "#{certs_dir}/#{filename}"
      FileUtils.ln_s filename, "#{fqdn}.#{ext}", force: true
      FileUtils.chown(nil,config["clusterlb"]["nginx_unix_group"],filename)

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

  def go_ssh(hostname,cmd,username)
    Net::SSH.start(hostname, username, :keys_only => true ) do |ssh|
      puts ssh.exec!(cmd)
    end
  end

  def ensure_dir_exitsts
    [
      "#{ENV["CLUSTERLB_HOME"]}/#{config["clusterlb"]["sites_enabled"]}",
      "#{ENV["CLUSTERLB_HOME"]}/#{config["clusterlb"]["sites"]}",
      "#{ENV["CLUSTERLB_HOME"]}/#{config["clusterlb"]["certificates_dir"]}"
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
        :lb_nodes_dns_postfix => "service_domain.internal.vpc",
        :certificates_dir => "certs",
        :nginx_unix_group => "nginx"
      },
      :aws => {
        :profile => "yourprofile",
        :region => "us-west-2",
        :ssl_cert_bucket => "s3-bucket-name"
      },
      :LetsEncrypt => {
        :sites_enabled => [],
        :challange_dir => "LetsEncrypt/challage",
        :certificates_dir => "LetsEncrypt/certs",
        :acme_home_dir => "LetsEncrypt/.acme.sh"
      }
    }
    File.open(path,"w") do |f|
      f.write(JSON.pretty_generate(example_config))
    end
  end




end
