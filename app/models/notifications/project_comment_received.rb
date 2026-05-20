module Notifications
  class ProjectCommentReceived < ::Notification
    self.default_priority     = :medium
    self.aggregatable         = true
    self.slack_template_path  = "notifications/creations/comment_created_dm"
    self.category_key         = :project_comment_received
    self.category_label       = "Comments on your project"
    self.category_description = "Someone commented on your project devlog or ship event"
    self.category_group       = "Social"
    self.digest_delay         = 5.minutes
    self.inbox_record_preloads = { commentable: { post: :project } }

    def self.build_group_key(record:, recipient:, **)
      "comment:#{record&.commentable_type}:#{record&.commentable_id}:#{recipient.id}"
    end

    def slack_locals
      comment = record
      return {} unless comment

      commentable = comment.commentable
      project = commentable.respond_to?(:post) ? commentable.post&.project : nil
      return {} unless project

      {
        commentable_title: sanitize_slack_mentions(project.title),
        commentable_url:   Rails.application.routes.url_helpers.project_url(project, host: "stardance.hackclub.com", protocol: "https"),
        author_name:       sanitize_slack_mentions(actor&.display_name) || "Someone",
        comment_body:      sanitize_slack_mentions(comment.body.to_s.truncate(200))
      }
    end

    def target_path
      project = record&.commentable.respond_to?(:post) ? record.commentable.post&.project : nil
      project ? Rails.application.routes.url_helpers.project_path(project) : nil
    end

    def preview_text
      record&.body.to_s.truncate(140).presence
    end

    def email_subject
      project = record&.commentable.respond_to?(:post) ? record.commentable.post&.project : nil
      who = actor&.display_name
      if project&.title.present? && who.present?
        "@#{who} commented on #{project.title}"
      elsif project&.title.present?
        "New comment on #{project.title}"
      else
        "New comment on your project"
      end
    end
  end
end
