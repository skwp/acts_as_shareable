require File.join(File.dirname(__FILE__), 'test_helper')
require "#{File.dirname(__FILE__)}/../lib/acts_as_shareable"

class Testuser < ActiveRecord::Base
  
end

#class Share < ActiveRecord::Base
#  belongs_to :shareable, :polymorphic => true
#  belongs_to :shared_to, :polymorphic => true
#  belongs_to :user
#  
#  def self.find_shares_by_user(user)
#    find(:all,
#      :conditions => ["user_id = ?", user.id],
#      :order => "created_at DESC"
#    )
#  end
#  
#  def self.find_by_shared_to(object)
#    to = ActiveRecord::Base.send(:class_name_of_active_record_descendant, object).to_s
#    find(:all, :conditions=>["shared_to_type=? and shared_to_id=?", to, object.id])
#  end
#  
#  def self.find_by_shareable_and_shared_to(shareable, object)
#    shareable = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s
#    to = ActiveRecord::Base.send(:class_name_of_active_record_descendant, object).to_s
#    Share.find(:first, :conditions=>["shareable_type = ? and shareable_id = ? and shared_to_type = ? and shared_to_id = ?",
#                    shareable, id, to, object.id])
#  end
#end

class Testbook < ActiveRecord::Base
  acts_as_shareable
end

class Testgroup < ActiveRecord::Base
end

class Testevent < ActiveRecord::Base
end

require "#{File.dirname(__FILE__)}/../lib/share"
require "pp"

class ActsAsShareableTest < Test::Unit::TestCase
  fixtures :testusers, :testbooks, :testgroups, :testevents, :shares
  
  def test_find_shares_by_user
    shares = Testbook.find_shares_by_user(testusers(:josh))
    assert_equal 4, shares.size, "josh should have four books shared"
    
    shares = Testbook.find_shares_by_user(testusers(:bob))
    assert_equal 1, shares.size, "bob should have one books shared"
  end
  
  def test_find_by_shared_to
    shares = Testbook.find_by_shared_to(testgroups(:reading))
    assert_equal 2, shares.size, "should be two books shared to reading group"
    
    shares = Testbook.find_by_shared_to(testevents(:party))
    assert_equal 2, shares.size, "should be one books shared to party event"
  end
  
  def test_find_by_shared_to_and_user
    shares = Testbook.find_by_shared_to_and_user(testgroups(:fun), testusers(:josh))
    assert_equal 1, shares.size, "should be one book shared to reading by josh"
    
    shares = Testbook.find_by_shared_to_and_user(testevents(:party), testusers(:bob))
    assert_equal 1, shares.size, "should be one book shared to party event by bob"
    
    shares = Testbook.find_by_shared_to_and_user(testgroups(:reading), testusers(:josh))
    assert_equal 2, shares.size, "should be two books shared to reading by josh"    
  end
  
  def test_shares_find_shares_by_user
    shares = Share.find_shares_by_user(testusers(:josh))
    assert_equal 4, shares.size, "josh should have four items shared"
    
    shares = Share.find_shares_by_user(testusers(:bob))
    assert_equal 1, shares.size, "bob should have one items shared"
  end
  
  def test_share_find_by_shared_to
    shares = Share.find_by_shared_to(testgroups(:reading))
    assert_equal 2, shares.size, "should be two books shared to reading group"
    
    shares = Share.find_by_shared_to(testevents(:party))
    assert_equal 2, shares.size, "should be one books shared to party event"
  end
  
  def test_find_by_shareable_and_shared_to
    shares = Share.find_by_shareable_and_shared_to(testbooks(:agile), testgroups(:reading))
    assert_equal 1, shares.size, "agile book should be shared to reading once"
    
    shares = Share.find_by_shareable_and_shared_to(testbooks(:rails), testevents(:party))
    assert_equal 2, shares.size, "rails book should be shared to party event twice"
  end
  
  def test_shared_to
    assert testbooks(:rails).shared_to?(testevents(:party), testusers(:bob)), 
      "rails should be shared to party by bob"
    assert_equal false, testbooks(:agile).shared_to?(testevents(:party), testusers(:josh)), 
      "agile shouldn't be shared to party by josh"
    assert testbooks(:agile).shared_to?(testgroups(:fun), testusers(:josh)), 
      "agile should be shared to fun by josh"
  end
  
  def test_share_to
    assert_equal 2, testbooks(:agile).shares.size, "agile should be shared 2 times"
    testbooks(:agile).share_to(testevents(:party), testusers(:josh))
    assert testbooks(:agile).shared_to?(testevents(:party), testusers(:josh)), 
      "agile should now be shared to party by josh"
    shares = Testbook.find_shares_by_user(testusers(:josh))
    assert_equal 5, shares.size, "josh should now have 5 books shared"
    assert_equal 3, testbooks(:agile).shares.size, "agile should be shared 3 times now"
    shares = Share.find_by_shared_to(testevents(:party))
    assert_equal 3, shares.size, "should be 3 books shared to party event"
    
    #just to check that you can't share the same thing to the same place twice
    testbooks(:agile).share_to(testevents(:party), testusers(:josh))
    assert_equal 3, testbooks(:agile).shares.size, "agile should be shared 3 times now"
  end
  
  def test_remove_share_to
    testbooks(:agile).remove_share_from(testgroups(:reading), testusers(:josh))
    assert_equal false, testbooks(:agile).shared_to?(testgroups(:reading), testusers(:josh)), 
      "agile should now be shared to party by josh"
    shares = Testbook.find_shares_by_user(testusers(:josh))
    assert_equal 3, shares.size, "josh should now have 3 books shared"
    assert_equal 1, testbooks(:agile).shares.size, "agile should be shared 1 time now"
    shares = Share.find_by_shared_to(testgroups(:reading))
    assert_equal 1, shares.size, "should be 3 books shared to reading group"
  end
  
  def test_find_shares_by_type
    shared_to = testbooks(:ruby).find_shared_to_by_type(Testgroup)
    assert_equal 1, shared_to.size, "should be shared to one place"
    assert_equal testgroups(:reading), shared_to[0], "should be shared to the reading group"
    
    shared_to = testbooks(:agile).find_shared_to_by_type(Testgroup, :limit=>1)
    assert_equal 1, shared_to.size, "should be shared to one place (because of limit)"
    assert_equal testgroups(:fun), shared_to[0], "should be shared to the reading group"
  end
  
end
