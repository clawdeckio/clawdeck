class CreateTaskArtifacts < ActiveRecord::Migration[8.1]
  def change
    create_table :task_artifacts do |t|
      t.references :task, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.references :blob, foreign_key: { to_table: :active_storage_blobs }
      t.string :name, null: false
      t.string :artifact_type, null: false, default: "file"
      t.string :file_path
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :task_artifacts, [ :task_id, :created_at ]
  end
end
