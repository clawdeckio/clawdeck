class AddModelToTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :model, :string
  end
end
