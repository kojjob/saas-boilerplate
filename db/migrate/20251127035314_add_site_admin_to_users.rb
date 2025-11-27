class AddSiteAdminToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :site_admin, :boolean
  end
end
