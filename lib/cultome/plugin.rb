
# Base module for plugin/commads/listeners that provide common funcionality.
module Plugin
	class PluginBase
		# Get and store a copy of the CultomePlayer instance to operate with.
		#
		# @param player [CultomePlayer] An instance of the player to operate with.
		def initialize(player)
			@p = player
		end

		# A shortcut for the CultomePlayer#display method.
		#
		# @param msg [Object] Any object that responds to #to_s.
		# @param continuos [Boolean] If false a new line character is appended at the end of message.
		# @return [String] The message printed.
		def display(msg, continuos=false)
			@p.display(msg, continuos)
		end

		def method_missing(method_name, *args)
			if @p.instance_variable_get("@#{method_name}").nil?
				# podria ser un metodo...
				# si no lo es, tira una exception
				method = @p.public_method method_name
				PluginBase.define_proxy method_name do |param|
					method.call param
				end
			else
				# es una variable
				PluginBase.define_proxy method_name do
					@p.instance_variable_get("@#{method_name}")
				end
			end

			send(method_name, *args)
		end

		def respond_to?(method)
			@p.respond_to?( method ) || super
		end

		def self.define_proxy(name, &block)
			define_method name, block
		end
	end
end