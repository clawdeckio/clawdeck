class AddCommentAndArtifactCountersToTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :comments_count, :integer, default: 0, null: false
    add_column :tasks, :artifacts_count, :integer, default: 0, null: false

    reversible do |dir|
      dir.up do
        # Backfill counters
        execute <<~SQL
          UPDATE tasks
          SET comments_count = sub.cnt
          FROM (
            SELECT task_id, COUNT(*) AS cnt
            FROM task_comments
            GROUP BY task_id
          ) sub
          WHERE tasks.id = sub.task_id;
        SQL

        execute <<~SQL
          UPDATE tasks
          SET artifacts_count = sub.cnt
          FROM (
            SELECT task_id, COUNT(*) AS cnt
            FROM task_artifacts
            GROUP BY task_id
          ) sub
          WHERE tasks.id = sub.task_id;
        SQL
      end
    end
  end
end
