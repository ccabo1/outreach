class AddUninterestedToContacts < ActiveRecord::Migration[5.1]
  def change
    add_column :contacts, :uninterested, :boolean
  end
end
