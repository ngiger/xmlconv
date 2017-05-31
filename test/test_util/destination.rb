#!/usr/bin/env ruby
# TestDestination -- xmlconv2 -- 08.06.2004 -- hwyss@ywesee.com

$: << File.dirname(__FILE__)
$: << File.expand_path('..', File.dirname(__FILE__))
$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'xmlconv/util/destination'
require 'xmlconv/config'
require 'minitest/autorun'
require 'flexmock/minitest'

module XmlConv
	module Util
    class DestinationMail
      def odba_store
      end
    end
		class TestDestination < ::Minitest::Test
			def setup
				@destination = Destination.new
        super
			end
			def test_attr_accessors
				assert_respond_to(@destination, :path)
				assert_respond_to(@destination, :path=)
			end
			def test_attr_readers
				assert_respond_to(@destination, :uri)
				assert_respond_to(@destination, :status)
				assert_respond_to(@destination, :update_status)
			end
			def test_deliver__destination
				delivery = flexmock('Delivery')
				assert_raises(RuntimeError) {
					@destination.deliver(delivery)
				}
			end
			def test_forget_credentials
				assert_respond_to(@destination, :forget_credentials!)
			end
      def test_book
        assert_instance_of(DestinationDir, Destination.book('/'))
        assert_instance_of(DestinationHttp,
                           Destination.book('http://www.example.com'))
        assert_instance_of(DestinationFtp,
                           Destination.book('ftp://www.example.com'))
      end
		end
		class TestDestinationDir < ::Minitest::Test
			def setup
				@destination = DestinationDir.new
				@target_dir = File.expand_path('data/destination',
					File.dirname(__FILE__))
        super
			end
			def teardown
				if(File.exist?(@target_dir))
					FileUtils.rm_r(@target_dir)
				end
        super
			end
			def test_attr_readers
				assert_respond_to(@destination, :filename)
			end
			def test_deliver__dir
				storage = flexmock('Storage')
				storage.should_receive(:transaction).and_return { |block|
					block.call
				}
				ODBA.storage = storage
				cache = flexmock('Cache')
				ODBA.cache = cache
				cache.should_receive(:store).and_return { |obj|
					assert_equal(@destination, obj)
				}
				delivery = flexmock('Delivery')
				delivery.should_receive(:filename).and_return { 'test_file.dat' }
				if(File.exist?(@target_dir))
					FileUtils.rm_r(@target_dir)
				end
				@destination.path = @target_dir
				@destination.deliver(delivery)
				target_file = File.expand_path('test_file.dat', @target_dir)
				assert(File.exist?(@target_dir), "Target Directory was not created")
				assert(File.exist?(target_file), "Target File was not written")
				assert_equal(delivery.to_s, File.read(target_file))
				assert_equal('test_file.dat', @destination.filename)
				assert_equal(:pending_pickup, @destination.status)
			ensure
				ODBA.storage = nil
				ODBA.cache = nil
			end
			def test_uri
				@destination.path = '/foo/bar/baz'
				assert_instance_of(URI::Generic, @destination.uri)
				assert_equal("file:/foo/bar/baz", @destination.uri.to_s)
				@destination.instance_variable_set('@filename', 'test_file.dat')
				assert_equal("file:/foo/bar/baz/test_file.dat", @destination.uri.to_s)
			end
			def test_status
				storage = flexmock('Storage')
				storage.should_receive(:transaction).and_return { |block|
					block.call
				}
				ODBA.storage = storage
				cache = flexmock('Cache')
				ODBA.cache = cache
				cache.should_receive(:store).and_return { |obj|
					assert_equal(@destination, obj)
				}
				assert_equal(:open, @destination.status)
				@destination.update_status
				assert_equal(:open, @destination.status)
				@destination.instance_variable_set('@status', :pending_pickup)
				@destination.instance_variable_set('@filename', 'no_such.file')
				assert_equal(:pending_pickup, @destination.status)
				@destination.update_status
				assert_equal(:picked_up, @destination.status)
				@destination.update_status
				assert_equal(:picked_up, @destination.status)
			ensure
				ODBA.storage = nil
				ODBA.cache = nil
			end
			def test_status_comparable
				assert_equal(0, @destination.status_comparable)
				@destination.instance_variable_set('@status', :pending_pickup)
				assert_equal(10, @destination.status_comparable)
				@destination.instance_variable_set('@status', :picked_up)
				assert_equal(20, @destination.status_comparable)
			end
		end
		class TestRemoteDestination < ::Minitest::Test
			def setup
				@destination = RemoteDestination.new
        super
			end
			def test_attr_accessors
				assert_respond_to(@destination, :path)
				assert_respond_to(@destination, :path=)
				assert_respond_to(@destination, :uri)
				assert_respond_to(@destination, :uri=)
				assert_respond_to(@destination, :host)
				assert_respond_to(@destination, :host=)
			end
		end
    class TestDestinationMail< ::Minitest::Test
      def setup
        @destination = DestinationMail.new
        ::Mail.defaults do delivery_method :test end
        ::Mail::TestMailer.deliveries.clear
        super
      end
      def test_destination_mail
        default_dest = 'mailto:noone@nowhere.org'
        test_recicpient = 'test@other.org'
        assert_equal(default_dest, @destination.uri.to_s)
        @destination.deliver('body as text')
        assert_equal(1, ::Mail::TestMailer.deliveries.length)
      end
    end
		class TestDestinationHttp < ::Minitest::Test
			def setup
				@destination = DestinationHttp.new
        @destination.transport = @transport = flexmock('DestinationHttp::HTTP_CLASS')
        super
			end
			def test_path_writer
				assert_equal('http:/', @destination.uri.to_s)
				@destination.path = '/foo/bar'
				assert_equal('http:/foo/bar', @destination.uri.to_s)
			end
			def test_host_writer
				assert_equal('http:/', @destination.uri.to_s)
				@destination.host = 'www.example.org'
				assert_equal('http://www.example.org/', @destination.uri.to_s)
			end
			def test_uri_writer
				uri = URI.parse('http://www.example.org/foo/bar')
				assert_instance_of(URI::HTTP, @destination.uri)
				assert_equal('http:/', @destination.uri.to_s)
				@destination.uri = uri
				assert_instance_of(URI::HTTP, @destination.uri)
				assert_equal('http://www.example.org/foo/bar', @destination.uri.to_s)
				@destination.uri = 'http://www.example.com/foo/bar'
				assert_instance_of(URI::HTTP, @destination.uri)
				assert_equal('http://www.example.com/foo/bar', @destination.uri.to_s)
			end
			def test_deliver__http
				@destination.uri = 'http://testaccount:password@xmlconv.ywesee.com:12345/test.rbx'
				http_session = flexmock('HttpSession')
				delivery = flexmock('Delivery')
				response = flexmock('Response')
				response.should_receive(:message).and_return { 'Status' }
				delivery.should_receive(:to_s).and_return { 'The Delivery' }
				http_session.should_receive(:request).and_return { |post_request, body|
					assert_instance_of(Net::HTTP::Post, post_request)
					header = post_request.instance_variable_get('@header')
					assert_equal(['text/xml'], header['content-type'])
					assert(header.include?('authorization'), "Authorization-Headers not sent")
					assert_equal('The Delivery', body)
					response
				}
				@transport.should_receive(:start).and_return { |host, port, block|
					assert_equal('xmlconv.ywesee.com', host)
					assert_equal(12345, port)
					block.call(http_session)
				}
				@destination.deliver(delivery)
				assert_equal(:http_status, @destination.status)
				# When the delivery is delivered, forget username and Password
				uri = @destination.uri
				assert_nil(uri.user)
				assert_nil(uri.password)
				assert_equal('http://xmlconv.ywesee.com:12345/test.rbx', uri.to_s)
			end
		end
		class TestDestinationFtp < ::Minitest::Test
			def setup
				@destination = DestinationFtp.new
        @destination.transport = @transport = flexmock('DestinationFtp::FTP_CLASS')
        super
			end
			def test_path_absolute_writer
				assert_equal('ftp:/', @destination.uri.to_s)
				@destination.path = '/foo/bar'
				assert_equal('ftp:/%2Ffoo/bar', @destination.uri.to_s)
			end
			def test_path_relative_writer
				assert_equal('ftp:/', @destination.uri.to_s)
				@destination.path = 'foo/bar'
				assert_equal('ftp:/foo/bar', @destination.uri.to_s)
			end
			def test_host_writer
				assert_equal('ftp:/', @destination.uri.to_s)
				@destination.host = 'www.example.org'
				assert_equal('ftp://www.example.org/', @destination.uri.to_s)
			end
			def test_uri_writer
				uri = URI.parse('ftp://www.example.org/foo/bar')
				assert_instance_of(URI::FTP, @destination.uri)
				assert_equal('ftp:/', @destination.uri.to_s)
				@destination.uri = uri
				assert_instance_of(URI::FTP, @destination.uri)
				assert_equal('ftp://www.example.org/foo/bar', @destination.uri.to_s)
				@destination.uri = 'ftp://www.example.com/foo/bar'
				assert_instance_of(URI::FTP, @destination.uri)
				assert_equal('ftp://www.example.com/foo/bar', @destination.uri.to_s)
			end
			def test_deliver__ftp
				@destination.uri = 'ftp://testaccount:password@xmlconv.ywesee.com/foo/bar/'
				ftp_session = flexmock('FtpSession')
				delivery = flexmock('Delivery')
				delivery.should_receive(:to_s).and_return { 'The Delivery' }
        delivery.should_receive(:filename).and_return { 'test.dat' }
        ftp_session.should_receive(:chdir).and_return { |path|
          assert_equal('foo/bar/', path)
        }
        ftp_session.should_receive(:puttextfile).and_return { |local, remote|
          assert_equal("The Delivery\n", File.read(local))
          assert_equal('test.dat', remote)
        }
				@transport.should_receive(:open).and_return { |host, user, password, block|
					assert_equal('xmlconv.ywesee.com', host)
					assert_equal('testaccount', user)
					assert_equal('password', password)
					block.call(ftp_session)
				}
				@destination.deliver(delivery)
				assert_equal(:ftp_ok, @destination.status)
				# When the delivery is delivered, forget username and Password
				uri = @destination.uri
				assert_nil(uri.user)
				assert_nil(uri.password)
				assert_equal('ftp://xmlconv.ywesee.com:21/foo/bar/', uri.to_s)
			end
			def test_deliver__many
				@destination.uri = 'ftp://testaccount:password@xmlconv.ywesee.com/foo/bar/'
				ftp_session = flexmock('FtpSession')
				delivery = flexmock('Delivery')
				delivery.should_receive(:to_s).and_return { 'The Delivery' }
        delivery.should_receive(:filename).and_return { 'test.dat' }
				delivery.should_receive(:to_s).and_return { 'The Delivery' }
        delivery.should_receive(:filename).and_return { 'test.dat' }
        ftp_session.should_receive(:chdir).and_return { |path|
          assert_equal('foo/bar/', path)
        }
        expecteds = %w{test.dat test.dat}
        ftp_session.should_receive(:puttextfile).times(2)\
          .and_return { |local, remote|
          assert_equal("The Delivery\n", File.read(local))
          assert_equal(expecteds.shift, remote)
        }
				@transport.should_receive(:open).and_return { |host, user, password, block|
					assert_equal('xmlconv.ywesee.com', host)
					assert_equal('testaccount', user)
					assert_equal('password', password)
					block.call(ftp_session)
				}
				@destination.deliver([delivery, delivery])
				assert_equal(:ftp_ok, @destination.status)
				# When the delivery is delivered, forget username and Password
				uri = @destination.uri
				assert_nil(uri.user)
				assert_nil(uri.password)
				assert_equal('ftp://xmlconv.ywesee.com:21/foo/bar/', uri.to_s)
			end
      def test_deliver_tmp
        path = 'ftp://testaccount:password@xmlconv.ywesee.com/foo/bar/'
        tmp = '/foo/tmp/'
        @destination = Destination.book(path, tmp)
        @destination.transport = @transport = flexmock('DestinationHttp::FTP_CLASS')
        ftp_session = flexmock('FtpSession')
        delivery = flexmock('Delivery')
        delivery.should_receive(:to_s).and_return { 'The Delivery' }
        delivery.should_receive(:filename).and_return { 'test.dat' }
        ftp_session.should_receive(:chdir).with('foo/bar/')
        ftp_session.should_receive(:puttextfile).and_return { |local, remote|
          assert_equal("The Delivery\n", File.read(local))
          assert_equal('/foo/tmp/test.dat', remote)
        }
        ftp_session.should_receive(:rename).with('/foo/tmp/test.dat', 'test.dat').times(1)
        @transport.should_receive(:open).and_return { |host, user, password, block|
          assert_equal('xmlconv.ywesee.com', host)
          assert_equal('testaccount', user)
          assert_equal('password', password)
          block.call(ftp_session)
        }
        @destination.deliver(delivery)
        assert_equal(:ftp_ok, @destination.status)
        # When the delivery is delivered, forget username and Password
        uri = @destination.uri
        assert_nil(uri.user)
        assert_nil(uri.password)
        assert_equal('ftp://xmlconv.ywesee.com:21/foo/bar/', uri.to_s)
      end
		end
=begin
    class TestDestinationSftp < ::Minitest::Test
      def setup
        @destination = DestinationSftp.new
        @destination.transport = @transport = flexmock('DestinationSftp::SFTP_CLASS')
        super
      end
      def test_path_writer
        assert_equal('sftp:/', @destination.uri.to_s)
        @destination.path = '/foo/bar'
        assert_equal('sftp:/foo/bar', @destination.uri.to_s)
      end
      def test_host_writer
        assert_equal('sftp:/', @destination.uri.to_s)
        @destination.host = 'www.example.org'
        assert_equal('sftp://www.example.org/', @destination.uri.to_s)
      end
      def test_uri_writer
        uri = URI.parse('sftp://www.example.org/foo/bar')
        assert_instance_of(URI::Generic, @destination.uri)
        assert_equal('sftp:/', @destination.uri.to_s)
        @destination.uri = uri
        assert_instance_of(URI::Generic, @destination.uri)
        assert_equal('sftp://www.example.org/foo/bar', @destination.uri.to_s)
        @destination.uri = 'sftp://www.example.com/foo/bar'
        assert_instance_of(URI::Generic, @destination.uri)
        assert_equal('sftp://www.example.com/foo/bar', @destination.uri.to_s)
      end
      def test_deliver__sftp
        @destination.uri = 'sftp://testaccount@xmlconv.ywesee.com/foo/bar/'
        file_operations = flexmock 'SftpFileOperations'
        sftp_session = flexmock('SftpSession')
        sftp_session.should_receive(:file).and_return file_operations
        delivery = flexmock('Delivery')
        delivery.should_receive(:to_s).and_return { 'The Delivery' }
        delivery.should_receive(:filename).and_return { 'test.dat' }
        file_handle = StringIO.new('')
        @transport.should_receive(:start).and_return { |host, user, opts, block|
          assert_equal('xmlconv.ywesee.com', host)
          assert_equal('testaccount', user)
          assert_equal([], opts[:keys])
          assert_instance_of(String, opts[:user_known_hosts_file])
          block.call(sftp_session)
        }
        file_operations.should_receive(:open).and_return do |path, mode, block|
          assert_equal '/foo/bar/test.dat', path
          assert_equal 'w', mode
          block.call file_handle
        end
        @destination.deliver(delivery)
        assert_equal(:sftp_ok, @destination.status)
        file_handle.rewind
        assert_equal "The Delivery\n", file_handle.read
        # When the delivery is delivered, forget username and Password
        uri = @destination.uri
        assert_nil(uri.user)
        assert_nil(uri.password)
        assert_equal('sftp://xmlconv.ywesee.com/foo/bar/', uri.to_s)
      end
      def test_deliver__many
        @destination.uri = 'sftp://testaccount@xmlconv.ywesee.com/foo/bar/'
        file_operations = flexmock 'SftpFileOperations'
        sftp_session = flexmock('SftpSession')
        sftp_session.should_receive(:file).and_return file_operations
        delivery = flexmock('Delivery')
        delivery.should_receive(:to_s).and_return { 'The Delivery' }
        delivery.should_receive(:filename).and_return { 'test.dat' }
        file_handle = StringIO.new('')
        @transport.should_receive(:start).and_return { |host, user, opts, block|
          assert_equal('xmlconv.ywesee.com', host)
          assert_equal('testaccount', user)
          assert_equal([], opts[:keys])
          assert_instance_of(String, opts[:user_known_hosts_file])
          block.call(sftp_session)
        }
        expecteds = %w{/foo/bar/test.dat /foo/bar/test.dat}
        file_operations.should_receive(:open).and_return do |path, mode, block|
          assert_equal(expecteds.shift, path)
          assert_equal 'w', mode
          block.call file_handle
        end
        @destination.deliver([delivery, delivery])
        assert_equal(:sftp_ok, @destination.status)
        file_handle.rewind
        assert_equal "The Delivery\n" * 2, file_handle.read
        # When the delivery is delivered, forget username and Password
        uri = @destination.uri
        assert_nil(uri.user)
        assert_nil(uri.password)
        assert_equal('sftp://xmlconv.ywesee.com/foo/bar/', uri.to_s)
      end
    end
=end
	end
end
