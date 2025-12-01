class AddUnitToMaterialEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :material_entries, :unit, :string
  end
end
