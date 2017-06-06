#!/usr/bin/env ruby
# Config -- xmlconv2 -- 21.08.2006 -- hwyss@ywesee.com

require 'rclconf/rclconf'

module XmlConv
  conf_dir = '/etc/xmlconv'
  data_dir = '/var/lib/xmlconv'
  code_dir = '/usr/lib/xmlconv'
  if(home = ENV['HOME'])
    conf_dir = File.join(home, '.xmlconv')
    data_dir = File.join(conf_dir, 'data')
    code_dir = File.join(conf_dir, 'plugin')
  elsif(document_root = ENV['DOCUMENT_ROOT'])
    conf_dir = File.join(document_root, 'etc')
    data_dir = File.join(document_root, 'data')
    code_dir = File.join(document_root, 'lib')
  end
  default_config_files = [
    File.join(conf_dir, 'xmlconv.yml'),
    '/etc/xmlconv/xmlconv.yml',
  ]
  defaults = {
    'access'              => {},
    'commission'          => 0.3, ## Commission in percent
    'config'              => default_config_files,
    'bbmb_url'            => 'druby://localhost:12004',
    'db_name'             => 'xmlconv',
    'db_user'             => 'xmlconv',
    'db_auth'             => '',
    'default_filename'    => '%s%s_%s.dat',
    'grammar_dir'         => data_dir,
    'group_commissions'   => {}, ## Commission per Group in percent
    'invoice_format'      => "Commission %s-%s",
    'invoice_item_format' => "Commission %s\n%s %1.2f Turnover\nout of %i transmitted invoices",
    'log_file'            => STDERR,
    'log_level'           => 'INFO',
    'mail_host'           => 'localhost',
    'mail_from'           => 'xmlconv@ywesee.com',
    'pass_hash'           => nil,
    'polling_file'        => conf_dir,
    'polling_interval'    => nil,
    'program_name'        => 'XmlConv2',
    'project_root'        => data_dir,
    'plugin_dir'          => File.expand_path('conversion', code_dir),
    'postproc_dir'        => File.expand_path('postprocess', code_dir),
    'run_invoicer'        => false, ## Defaults to false, since most xmlconv
                                    #  applications delegate invoicing to bbmb
    'server_url'          => 'druby://localhost:10010',
    'ssh_identities'      => [],
    'ssh_known_hosts_file'=> File.expand_path('known_hosts', conf_dir),
    'target_format_fs'    => ',',
    'target_format_rs'    => "\n",
    'smtp_server'         => 'smtp.gmail.com',
    'smtp_user'           => 'nouser@nowhere.com',
    'smtp_domain'         => 'no.domain.com',
    'smtp_authtype'       => 'plain',
    'smtp_port'           => '587',
    'smtp_pass'           => 'thisIsNotApassword',
    'ydim_id'             => nil,
    'ydim_config'         => nil,
    'vat_rate'            => 7.6,
    'reader'              => 'XundartBdd',
    'writer'              => 'BddCsv',
  }

  config = RCLConf::RCLConf.new(ARGV, defaults)
  config.load(config.config)

  CONFIG = config
end
