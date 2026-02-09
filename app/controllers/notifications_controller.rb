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
    current_user.notifications.unread.update_all(read_at: Time.current)
    redirect_back fallback_location: boards_path
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end
end
