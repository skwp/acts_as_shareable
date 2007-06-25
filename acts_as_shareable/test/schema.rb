ActiveRecord::Schema.define(:version => 1) do

  create_table :testusers, :force => true do |t|
    t.column :name, :string, :limit => 50
  end

  create_table :shares, :force => true do |t|
    t.column :user_id,          :integer
    t.column :shareable_id,     :integer
    t.column :shareable_type,   :string, :limit => 30
    t.column :shared_to_type,   :string, :limit => 30
    t.column :shared_to_id,     :integer
    t.column :created_at,       :datetime
    t.column :updated_at,       :datetime
  end

  create_table :testbooks, :force => true do |t|
    t.column :title,            :string, :limit => 50
  end
  
  create_table :testgroups, :force => true do |t|
    t.column :title,            :string, :limit => 50
  end
  
  create_table :testevents, :force => true do |t|
    t.column :title,            :string, :limit => 50
  end

end
  