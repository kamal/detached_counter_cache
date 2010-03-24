TEST_ROOT = File.dirname(__FILE__)
require File.join(TEST_ROOT, 'test_helper')

class DetachedCounterCacheTest < ActiveSupport::TestCase
  include ActiveRecord::TestFixtures
  self.use_instantiated_fixtures  = false
  self.use_transactional_fixtures = true
  self.pre_loaded_fixtures = true
  
  def test_wristbands_count_should_be_zero_for_new_user
    assert_equal 0, User.new.wristbands.size
  end
  
  def test_creating_wristband_increments_count
    user = User.create
    user.wristbands.create
    assert_equal 1, user.wristbands.size
  end

  def test_creating_wristband_creates_user_wristbands_count_record
    user = User.create
    assert !UsersWristbandsCount.find_by_user_id(user.id)
    user.wristbands.create
    assert UsersWristbandsCount.find_by_user_id(user.id)
  end

  def test_creating_second_wristband_doesnt_create_second_count_record
    user = User.create
    user.wristbands.create
    user.wristbands.create
    assert_equal 1, UsersWristbandsCount.count(:conditions => { :user_id => user.id })
  end

  def test_creating_second_wristband_increments_count_record
    user = User.create
    user.wristbands.create
    user.wristbands.create
    assert_equal 2, UsersWristbandsCount.find_by_user_id(user.id).count
  end
  
  def test_destroying_wristband_decrements_count_record
    user = User.create
    user.wristbands.create
    wristband = user.wristbands.create
    wristband.destroy
    assert_equal 1, UsersWristbandsCount.find_by_user_id(user.id).count
  end
  
  def test_updating_user_wristbands_count_record_updates_association_size
    user = User.create
    user.wristbands.create
    
    wristbands_count = UsersWristbandsCount.find_by_user_id(user.id)
    wristbands_count.update_attribute(:count, 5)
    
    assert_equal 5, user.reload.wristbands.size
  end
  
  def test_ordinary_counter_caches_work
    user = User.create
    user.globes.create
    assert_equal 1, user.reload.globes_count
    assert_equal 1, user.reload.globes.size
  end
  
  def test_ordinary_counter_cache_with_owner_having_no_detached_counter_caches
    globe = Globe.create
    globe.latitudes.create
    assert_equal 1, globe.reload.latitudes_count
    assert_equal 1, globe.reload.latitudes.size
  end
  
  def test_has_many_size_with_no_count_record
    User.create.wristbands.size
  end
end
