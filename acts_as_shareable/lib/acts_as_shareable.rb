# ActsAsShareable
module CC
  module Acts #:nodoc:
    module Shareable #:nodoc:

      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def acts_as_shareable(options={})
          has_many :shares, :as => :shareable, :dependent => :destroy
          #TODO: have options specify the types that the shareable objects can be shared to
          #      only allow shares to those objects, also should add some methods to the classes
          #      that have have objects shared to them
          #this one goes on the objects that are allowed to have things shared to them
          #has_many :sharings, :as=> :shared_to :dependent => :destroy
          include CC::Acts::Shareable::InstanceMethods
          extend CC::Acts::Shareable::SingletonMethods
        end
      end

      module SingletonMethods
        # Add class methods here
        def find_shares_by_user(user, *opts)      
          shareable = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s
          options = {
            :joins=>"LEFT OUTER JOIN shares s ON s.shareable_id = #{self.table_name}.id",
            :select=>"#{self.table_name}.*",
            :conditions => ["s.user_id = ? AND s.shareable_type =?", user.id,shareable],
            :order => "s.created_at DESC"}

          self.find(:all, merge_options(options,opts))
        end
        
        def find_by_shared_to(object, *opts)
          shareable = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s
          shared_to = ActiveRecord::Base.send(:class_name_of_active_record_descendant, object.class).to_s
          options = {
            :joins=>"LEFT OUTER JOIN shares s ON s.shareable_id = #{self.table_name}.id",
            :select=>"#{self.table_name}.*",
            :conditions => ["s.shareable_type =? and s.shared_to_type=? and s.shared_to_id = ?", 
                            shareable, shared_to, object.id],
            :order => "s.created_at DESC"}

          self.find(:all, merge_options(options,opts))
        end
        
        def find_by_shared_to_and_user(object, user, *opts)
          shareable = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s
          shared_to = ActiveRecord::Base.send(:class_name_of_active_record_descendant, object.class).to_s
          options = {
            :joins=>"LEFT OUTER JOIN shares s ON s.shareable_id = #{self.table_name}.id",
            :select=>"#{self.table_name}.*",
            :conditions => ["s.user_id = ? AND s.shareable_type =? and s.shared_to_type=? and s.shared_to_id = ?", 
                            user.id,shareable, shared_to, object.id],
            :order => "s.created_at DESC"}


          self.find(:all, merge_options(options,opts))
        end
        
        private
        def merge_options(options, opts)
          if opts && opts[0].is_a?(Hash) && opts[0].has_key?(:conditions)
            cond = opts[0].delete(:conditions)
            options[:conditions][0] << " " << cond.delete_at(0)
            options[:conditions] + cond
          end
          options.merge!(opts[0]) if opts && opts[0].is_a?(Hash)
          return options
        end
        
      end

      module InstanceMethods
        # Add instance methods here
        
        def share_to(object, by_user, options={})
          unless shared_to?(object, by_user)
            s = Share.new(options.merge(:user_id=>by_user.id, :shared_to_type=>object.class.to_s, :shared_to_id=>object.id))
            self.shares << s
            #object.sharings << s
            self.save!
          end
        end
        
        def remove_share_from(object, by_user)
          shareable = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self.class).to_s
          to = ActiveRecord::Base.send(:class_name_of_active_record_descendant, object.class).to_s
          s = Share.find(:first, :conditions=>["shareable_type = ? and shareable_id = ? and shared_to_type = ? and shared_to_id = ? and user_id=?",
                          shareable, id, to, object.id, by_user.id])
          if s
            s.destroy
            reload
            #object.reload
          end
        end
        
        def shared_to?(object, by_user)
          shareable = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self.class).to_s
          to = ActiveRecord::Base.send(:class_name_of_active_record_descendant, object.class).to_s
          s = Share.find(:first, :conditions=>["shareable_type = ? and shareable_id = ? and shared_to_type = ? and shared_to_id = ? and user_id=?",
                          shareable, id, to, object.id, by_user.id])
          return !s.nil?
        end
        
        def find_shared_to_by_type(shared_type, *opts)
          shareable = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self.class).to_s
          shared_to = ActiveRecord::Base.send(:class_name_of_active_record_descendant, shared_type)
          options = {
            :joins=>"LEFT OUTER JOIN shares s ON s.shared_to_id = #{Object.const_get(shared_to).table_name}.id",
            :select=>"#{Object.const_get(shared_to).table_name}.*",
            :conditions => ["s.shareable_type =? and s.shared_to_type=? and s.shareable_id = ?", 
                            shareable, shared_to.to_s, id],
            :order => "s.created_at DESC"}

          Object.const_get(shared_to).find(:all, merge_options(options,opts))
        end
        
        private
        def merge_options(options, opts)
          if opts && opts[0].is_a?(Hash) && opts[0].has_key?(:conditions)
            cond = opts[0].delete(:conditions)
            options[:conditions][0] << " " << cond.delete_at(0)
            options[:conditions] + cond
          end
          options.merge!(opts[0]) if opts && opts[0].is_a?(Hash)
          return options
        end
      end
    end
  end
end