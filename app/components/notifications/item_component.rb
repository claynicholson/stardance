module Notifications
  class ItemComponent < ViewComponent::Base
    delegate :inline_svg_tag, to: :helpers

    TYPE_ICONS = {
      "Notifications::NewFollower"                              => "person",
      "Notifications::ProjectFollowed"                          => "person",
      "Notifications::ProjectCommentReceived"                   => "comment",
      "Notifications::FollowedDevlogCreated"                    => "pencil",
      "Notifications::StardustBalanceChanged"                   => "sparkle",
      "Notifications::Payouts::ShipEventIssued"                 => "rocket",
      "Notifications::Payouts::VoteDeficitBlocked"              => "thumbs-up",
      "Notifications::Projects::SuperStar"                      => "star",
      "Notifications::Missions::SubmissionApproved"             => "check-circle",
      "Notifications::Missions::SubmissionRejected"             => "alert-triangle",
      "Notifications::Missions::SubmissionPendingForReviewer"   => "clipboard",
      "Notifications::ShopOrders::StatusChanged"                => "bag"
    }.freeze

    attr_reader :notification

    def initialize(notification:)
      @notification = notification
    end

    def li_classes
      [
        "notifications-item",
        ("notifications-item--unread" if notification.read_at.nil?),
        "notifications-item--priority-#{notification.priority}"
      ].compact.join(" ")
    end

    def time_text
      helpers.time_ago_in_words(notification.created_at) + " ago"
    end

    def type_icon_path
      name = TYPE_ICONS[notification.type] || "bell"
      "icons/notifications/#{name}.svg"
    end

    def avatar_actor
      notification.actor
    end

    def others_count
      return 0 if notification.group_count.to_i <= 1

      notification.group_count - 1
    end
  end
end
