#!/usr/bin/env ruby
# PartyContainer -- xmlconv2 -- 01.06.2004 -- hwyss@ywesee.com

module XmlConv
	module Model
		module PartyContainer
			attr_accessor :customer, :employee, :ship_to, :bill_to
			def add_party(party)
				if((role = party.role) && !role.empty?)
					role = role.gsub(/\B[A-Z]/, '_\&')
					instance_variable_set("@#{role.downcase}", party)
					parties.push(party)
				end
			end
			def parties
				@parties ||= []
			end
		end
	end
end
