class NotificationsController < ApplicationController
  before_action :set_notification, only: [ :read, :unread ]

  def read
    @notification.mark_read!
    redirect_back fallback_location: boards_path
  end

  def unread
    @notification.mark_unread!
    redirect_back fallback_location: boards_path
  end

  def read_all
    Notification.for_user(current_user).unread.update_all(read_at: Time.current)
    redirect_back fallback_location: boards_path
  end

  private

  def set_notification
    @notification = Notification.for_user(current_user).find(params[:id])
  end
end
