#!/usr/bin/env ruby
# XmlConv -- xmlconv2 -- 07.06.2004 -- hwyss@ywesee.com

$: << File.expand_path('..', File.dirname(__FILE__))

require 'drb/drb'
require 'util/application'
require 'etc/config'

$0 = "XmlConv2"

xmlconv = XmlConvApp.new

DRb.start_service(XmlConv::SERVER_URI, xmlconv)
puts 'drb-service started'

DRb.thread.join
