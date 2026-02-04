class ProcessRecurringTasksJob < ApplicationJob
  queue_as :default

  # Run every hour to check for recurring tasks that need new instances created
  def perform
    Rails.logger.info "[RecurringTasks] Starting recurring task processing..."

    tasks_processed = 0
    instances_created = 0

    Task.unscoped.due_for_recurrence.find_each do |task|
      begin
        Rails.logger.info "[RecurringTasks] Processing recurring task ##{task.id}: #{task.name}"

        # Create a new instance of the recurring task
        instance = task.create_recurring_instance!
        instances_created += 1

        Rails.logger.info "[RecurringTasks] Created instance ##{instance.id} for recurring task ##{task.id}"

        # Schedule the next recurrence
        task.schedule_next_recurrence!

        Rails.logger.info "[RecurringTasks] Next recurrence for ##{task.id} scheduled at #{task.next_recurrence_at}"

        tasks_processed += 1
      rescue => e
        Rails.logger.error "[RecurringTasks] Error processing task ##{task.id}: #{e.message}"
        Rails.logger.error e.backtrace.first(5).join("\n")
      end
    end

    Rails.logger.info "[RecurringTasks] Completed. Processed #{tasks_processed} tasks, created #{instances_created} instances."

    { tasks_processed: tasks_processed, instances_created: instances_created }
  end
end
