require 'rubygems'
require 'test/unit'
require 'active_record'
require 'active_record/fixtures'
require 'mocha'
require 'yaml'

ActiveRecord::Base.configurations = YAML::load(File.open(File.join(File.dirname(__FILE__), 'database.yml')))
ActiveRecord::Base.establish_connection(:detached_counter_cache_test)
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + '/debug.log')

ActiveRecord::Schema.define do
  create_table "users", :force => true do |t|
    t.string  "username"
    t.integer "globes_count"
  end
  
  create_table "wristbands", :force => true do |t|
    t.integer  "user_id"
  end
  
  create_table "globes", :force => true do |t|
    t.integer  "user_id"
    t.integer  'latitudes_count'
  end
  
  create_table "latitudes", :force => true do |t|
    t.integer  'globe_id'
  end
  
  create_table "users_wristbands_counts", :force => true do |t|
    t.integer  "user_id"
    t.integer  "count", :default => 0
  end
  
  add_index "users_wristbands_counts", 'user_id', :unique => true
end

require 'init'

class Test::Unit::TestCase
  def assert_same_elements enum1, enum2, *args
    message = args.last.kind_of?(String) ? args.pop : "Expected Array #{enum1.inspect} to have same elements as #{enum2.inspect}."
    assert_block(build_message(message, "<?> expected to have the same elements as \n<?>.\n", enum2, enum1)) do
      if enum1.first.respond_to?(:<=>)
        enum1.sort == enum2.sort
      else
        enum1 == enum2
      end
    end
  end
end

class User < ActiveRecord::Base
  has_many :wristbands
  has_many :globes
end

class Wristband < ActiveRecord::Base
  belongs_to :user, :detached_counter_cache => true
end

class Globe < ActiveRecord::Base
  belongs_to :user, :counter_cache => true
  has_many :latitudes
end

class Latitude < ActiveRecord::Base
  belongs_to :globe, :counter_cache => true
end

class UsersWristbandsCount < ActiveRecord::Base
  belongs_to :user
end
