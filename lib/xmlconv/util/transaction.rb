#!/usr/bin/env ruby
# Util::Transaction -- xmlconv2 -- 10.05.2012 -- yasaka@ywesee.com
# Util::Transaction -- xmlconv2 -- 04.06.2004 -- hwyss@ywesee.com

require 'odba'
require 'xmlconv/util/destination'
require 'xmlconv/util/mail'

module XmlConv
	module Util
		class Transaction
			include ODBA::Persistable
			ODBA_SERIALIZABLE = ['@postprocs', '@responses', '@arguments']
      ODBA_PREFETCH = true
      odba_index :invoice_ids
      attr_accessor :input, :reader, :writer, :destination, :origin,
                    :transaction_id, :partner, :error, :postprocs,
                    :error_recipients, :debug_recipients, :domain,
                    :response, :arguments
			attr_reader :output, :model, :start_time, :commit_time,
									:input_model, :output_model
      def initialize
        @postprocs = []
      end
			def execute
				reader_instance = Conversion.const_get(@reader)
				writer_instance = Conversion.const_get(@writer)
				@start_time = Time.now
        @input = encode(@input)
        @input.gsub!(/\t+/, '')
        input_model = reader_instance.parse(encode(@input))
        @arguments ||= []
				@model = reader_instance.convert(input_model, *@arguments)
				output_model = writer_instance.convert(@model, *@arguments)
				@output = output_model.is_a?(Array) ? output_model.join("\n").to_s : output_model.to_s
				@destination.deliver(output_model)
				@commit_time = Time.now
				@output
			ensure
				@destination.forget_credentials!
			end

      # Assumes its encoding once as ISO-8859-1 (latin1) at here,
      # Because input_body is passed from ruby 1.8.6
      def encode(input_body)
        src = input_body.to_s
        begin
          # ISO-8859-1 (latin1) and WINDOWS-1252
          src.encode('ISO-8859-1').force_encoding('UTF-8')
        rescue Encoding::InvalidByteSequenceError,
               Encoding::UndefinedConversionError
          begin
            src.force_encoding('ISO-8859-1').encode('UTF-8')
          rescue
            src
          end
        end
      end

      def invoice_ids
        @model.invoices.collect do |inv|
          inv.invoice_id.last.to_s.gsub /^0+/, ''
        end
      end
			def notify
				recipients = [@debug_recipients]
				subject = 'XmlConv2 - Debug-Notification'
				if(@error)
					recipients.push(@error_recipients)
					subject = 'XmlConv2 - Error-Notification'
				end
				recipients.flatten!
				recipients.compact!
				recipients.uniq!
				return if(recipients.empty?)
				body = <<-EOS
Date:   #{@start_time.strftime("%d.%m.%Y")}
Time:   #{@start_time.strftime("%H:%M:%S")}
Status: #{status}
Error:  #{@error}
Link:   http://#{@domain}/de/transaction/transaction_id/#{@transaction_id}

Input:
# input start
#{@input}
# input end

Output:
# output start
#{@output}
# output end
				EOS
        Util::Mail.notify recipients, subject, body
			end
      def odba_store
        @input.extend(ODBA::Persistable) if(@input)
        @output.extend(ODBA::Persistable) if(@output)
        super
      end
      def postprocess
        if(@postprocs.respond_to?(:each))
          @postprocs.each { |klass, *args|
            next if args.empty?
            args.push(self)
            PostProcess.const_get(klass).send(*args)
          }
        end
      end
      def respond delivery, response
        responses[delivery] = response
      end
      def response
        reader_instance = Conversion.const_get(@reader)
        if reader_instance.respond_to?(:respond)
          reader_instance.respond(self, responses)
        end
      end
      def responses
        @responses ||= []
      end
			def status
				if(@error)
					:error
        elsif(@model.nil? || @model.empty?)
          :empty
				elsif(@destination.respond_to?(:status))
					@destination.status
				end
			end
      def status=(status)
        if @destination.respond_to?(:status=)
          @destination.status = status
          @destination.odba_store
          @destination.status
        end
      end
			def status_comparable
				if(@destination.respond_to?(:status_comparable))
					@destination.status_comparable 
				end
			end
			def update_status
				if(@destination.respond_to?(:update_status))
					@destination.update_status 
				end
			end
			def uri
				@destination.uri if(@destination.respond_to?(:uri))
			end
			def uri_comparable
				self.uri.to_s
			end
		end
	end
end
