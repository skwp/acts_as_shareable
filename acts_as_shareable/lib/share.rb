class Share < ActiveRecord::Base
  belongs_to :shareable, :polymorphic => true
  belongs_to :shared_to, :polymorphic => true
  belongs_to :user
  
  def self.find_shares_by_user(user)
    find(:all,
      :conditions => ["user_id = ?", user.id],
      :order => "created_at DESC"
    )
  end
  
  def self.find_by_shared_to(object)
    to = ActiveRecord::Base.send(:class_name_of_active_record_descendant, object.class).to_s
    find(:all, :conditions=>["shared_to_type=? and shared_to_id=?", to, object.id])
  end
  
  def self.find_by_shareable_and_shared_to(shareable, object)
    share = ActiveRecord::Base.send(:class_name_of_active_record_descendant, shareable.class).to_s
    to = ActiveRecord::Base.send(:class_name_of_active_record_descendant, object.class).to_s
    Share.find(:all, :conditions=>["shareable_type = ? and shareable_id = ? and shared_to_type = ? and shared_to_id = ?",
                    share, shareable.id, to, object.id])
  end
end