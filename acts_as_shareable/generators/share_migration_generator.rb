# Shamelessly derived from acts_as_commentable
class ShareMigrationGenerator < Rails::Generator::Base
  
  def manifest
    record do |m|
      m.migration_template 'migration.rb', 'db/migrate', :assigns => {
        :migration_name => "CreateShares"
      }, :migration_file_name => "create_shares"
    end
  end
end
