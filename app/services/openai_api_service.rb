class OpenaiApiService < AiService
  private

  def api_endpoint
    "https://api.openai.com/v1/chat/completions"
  end

  def headers
    {
      "Authorization" => "Bearer #{openai_api_key}",
      "Content-Type" => "application/json"
    }
  end

  def request_body(prompt)
    {
      model: "gpt-4o-mini",
      messages: [ { role: "user", content: prompt } ]
    }
  end

  def extract_content(json)
    json.dig("choices", 0, "message", "content")
  end

  def openai_api_key
    Rails.application.credentials.dig(:openai, :api_key) || ENV.fetch("OPENAI_API_KEY")
  end
end
