class My::NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    authorize :my, :show_notifications?

    @body_class = "app-layout-page"

    @pagy, @notifications = pagy(
      Notification.inbox_for(current_user).includes(:actor),
      limit: 25
    )

    Notification.preload_inbox_records!(@notifications)
    @notifications = @notifications.reject(&:orphaned?)
    @has_any_notifications = current_user.notifications.exists?
    @has_unread = @notifications.any? { |n| n.read_at.nil? }

    mark_all_unseen_as_seen!
  end

  def mark_read
    authorize :my, :update_notification?

    notification = current_user.notifications.find(params[:id])
    notification.mark_read!

    target = notification.target_path
    redirect_to(target.presence || my_notifications_path)
  end

  def mark_all_seen
    authorize :my, :update_notification?
    current_user.notifications.unseen.update_all(seen_at: Time.current)
    BroadcastUnseenCountJob.perform_later(current_user.id)
    redirect_back fallback_location: my_notifications_path
  end

  def mark_all_read
    authorize :my, :update_notification?
    current_user.notifications.unread.update_all(read_at: Time.current, seen_at: Time.current)
    BroadcastUnseenCountJob.perform_later(current_user.id)
    redirect_back fallback_location: my_notifications_path
  end

  def clear_all
    authorize :my, :update_notification?
    current_user.notifications.destroy_all
    BroadcastUnseenCountJob.perform_later(current_user.id)
    redirect_back fallback_location: my_notifications_path
  end

  private

  def authenticate_user!
    return if current_user.present?

    store_return_to
    redirect_to root_path, alert: "Please sign in to continue."
  end

  # Opening the inbox semantically means "I'm here, I've seen them" — so we
  # mark ALL unseen rows, not just the loaded page. Otherwise a user with
  # 100 unseen and a 25-per-page inbox would walk away with the badge stuck
  # at 75.
  def mark_all_unseen_as_seen!
    return if request.headers["Purpose"] == "prefetch"

    affected = current_user.notifications.unseen.update_all(seen_at: Time.current)
    BroadcastUnseenCountJob.perform_later(current_user.id) if affected.positive?
  end
end
