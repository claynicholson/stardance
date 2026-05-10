class SupportMailer < ApplicationMailer
  def forward(inbound_email)
    mail_message = inbound_email.mail
    @sender = mail_message.from.first
    @subject = mail_message.subject

    mail(
      to: Rails.application.credentials.dig(:jelly, :forwarding_address) || ENV.fetch("JELLY_SUPPORT_EMAIL", "jelly@hackclub.com"),
      from: "stardance@hackclub.com",
      reply_to: @sender,
      subject: "[Forwarded Support] #{@subject}"
    ) do |format|
      if mail_message.multipart?
        format.text { render plain: mail_message.text_part&.decoded } if mail_message.text_part
        format.html { render html: mail_message.html_part&.decoded&.html_safe } if mail_message.html_part
      else
        format.text { render plain: mail_message.body.decoded }
      end
    end
  end
end
