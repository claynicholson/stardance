class Rsvp::ReplyMailbox < ApplicationMailbox
  STOP_REGEX = /\bstop\b/i
  PUBLIC_ADDRESSES = %w[
    stardance@hackclub.com
    stardance-inbound@stardance.hackclub.com
  ].freeze
  SIGNUP_CONFIRMATION_SUBJECT = "confirm you're in for stardance"

  def process
    forwarded = should_forward?
    SupportMailer.forward(inbound_email).deliver_later if forwarded

    return if public_address? && !signup_confirmation_reply?

    sender = mail.from.first.to_s.downcase.strip
    rsvp = Rsvp.find_by(email: sender)
    return unless rsvp

    rsvp.confirm_reply!
    persist_reply(rsvp)

    return if forwarded

    if stop_requested?
      Rsvp::Game.current_for(rsvp)&.destroy
      Rsvp::Mailer.tic_tac_toe_stop(rsvp).deliver_later
    else
      advance_game(rsvp)
    end
  end

  private

  def should_forward?
    Rails.logger.debug("[Rsvp::ReplyMailbox] Checking if should forward. public_address?: #{public_address?}, stop_requested?: #{stop_requested?}")
    return false unless public_address?
    return false if parse_cell.present?
    return false if stop_requested?

    text = visible_reply.to_s.strip
    first_line = text.split("\n").first.to_s.strip
    return false if first_line.match?(/\A[1-9]\z/)

    downcased_clean = text.downcase.gsub(/[[:punct:]]/, "")
    Rails.logger.debug("[Rsvp::ReplyMailbox] Text for AI: #{text.inspect}")

    if downcased_clean == "hey stardance"
      Rails.logger.debug("[Rsvp::ReplyMailbox] Short-circuit ignore: hey stardance")
      return false
    end

    prompt = <<~PROMPT
      You are an email classifier for Stardance.
      Determine if the following email body is just a simple RSVP confirmation (e.g., "Hey Stardance", "I'm in!", possibly with a signature or sign-off) or if it contains an actual question, concern, or request that requires a support team member to respond.

      Rules:
      - If it is just "Hey Stardance" (even with a signature/sign-off), reply "ignore".
      - If it contains ANY question, request for help, or concern, reply "forward".
      - Be conservative: if in doubt, reply "forward".
      - Reply ONLY with one word: "forward" or "ignore".

      Email Body:
      #{text}
    PROMPT

    Rails.logger.debug("[Rsvp::ReplyMailbox] Calling OpenAI...")
    classification = OpenaiApiService.call(prompt).to_s.downcase.strip
    Rails.logger.debug("[Rsvp::ReplyMailbox] AI result: #{classification.inspect}")
    classification == "forward"
  rescue StandardError => e
    Rails.logger.error("[Rsvp::ReplyMailbox] AI classification failed: #{e.message}")
    true # Forward by default if AI fails
  end

  def public_address?
    recipients = Array(mail.to).map { |address| address.to_s.downcase.strip }
    (recipients & PUBLIC_ADDRESSES).any?
  end

  def signup_confirmation_reply?
    mail.subject.to_s.downcase.include?(SIGNUP_CONFIRMATION_SUBJECT)
  end

  def persist_reply(rsvp)
    rsvp.replies.find_or_create_by!(message_id: mail.message_id) do |reply|
      reply.subject     = mail.subject
      reply.body_text   = plain_body
      reply.body_html   = mail.html_part&.body&.decoded
      reply.received_at = mail.date || Time.current
    end
  end

  def advance_game(rsvp)
    game = Rsvp::Game.current_for(rsvp) || Rsvp::Game.start_for(rsvp)
    cell = parse_cell

    if cell.nil? && game.move_count.zero?
      Rsvp::Mailer.tic_tac_toe_start(game).deliver_later
      return
    end

    result = cell ? game.play_user_move(cell) : nil
    return if result == :invalid

    mailer_action = game.in_progress? ? :tic_tac_toe_move : :tic_tac_toe_over
    Rsvp::Mailer.public_send(mailer_action, game).deliver_later
  end

  def stop_requested?
    visible_reply.match?(STOP_REGEX)
  end

  def parse_cell
    digit = visible_reply.scan(/[1-9]/).first
    digit && (digit.to_i - 1)
  end

  def visible_reply
    EmailReplyParser.parse_reply(plain_body.to_s).to_s.strip
  end

  def plain_body
    return mail.text_part.body.decoded if mail.text_part
    return sanitize_html(mail.html_part.body.decoded) if mail.html_part
    return sanitize_html(mail.body.decoded) if mail.content_type.to_s.include?("text/html")

    mail.body.decoded
  end

  def sanitize_html(html)
    doc = Nokogiri::HTML.fragment(html.to_s)
    doc.css("blockquote, .gmail_quote, .gmail_attr").each(&:remove)
    doc.css("br").each { |n| n.replace(Nokogiri::XML::Text.new("\n", doc.document)) }
    doc.css("div, p, tr, li, h1, h2, h3, h4, h5, h6").each do |node|
      node.add_next_sibling(Nokogiri::XML::Text.new("\n", doc.document))
    end
    doc.text
  end
end
