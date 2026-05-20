class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    return reject if current_user.nil?

    stream_for current_user
  end

  # Fires on any seen-state change. Inbox controller ignores the absence of
  # `row_html` and just updates the badge.
  def self.broadcast_unseen_count(user)
    broadcast_to(user, { unseen_count: user.notifications.unseen.count })
  end

  # Fires when a new notification is created or an existing aggregate is
  # updated. Carries both the rendered row HTML (for live inbox insertion)
  # and the refreshed unseen count (for the sidebar badge).
  def self.broadcast_notification(notification, aggregated:)
    row_html = ApplicationController.render(
      partial: "notifications/inbox_row",
      locals: { notification: notification }
    )

    broadcast_to(
      notification.recipient,
      {
        unseen_count: notification.recipient.notifications.unseen.count,
        row_html: row_html,
        notification_id: notification.id,
        aggregated: aggregated
      }
    )
  end
end
