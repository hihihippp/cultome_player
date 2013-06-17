require 'coveralls'

Coveralls.wear!

# This file was generated by the `rspec --init` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# Require this file using `require "spec_helper"` to ensure that it is only
# loaded once.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.filter_run_excluding :resources

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
end

require 'cultome_player'
require 'cultome_player/helper'

include CultomePlayer::Helper

class TestOutput
    def print(msg)
    end

    def puts(msg)
    end
end

class Test
    include CultomePlayer

    def initialize
        set_environment({
            user_dir: "#{project_path}/spec/data/user"
        })
    end

    def player_output
        TestOutput.new
    end

    16.times do |idx|
        define_method "c#{idx}" do |str|
            return str
        end
    end
end

require 'active_record'

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: "#{project_path}/spec/data/user/db_cultome.dat")
