module OgImage
  class Start < Base
    PREVIEWS = {
      "default" => -> { new }
    }.freeze

    def render
      welcome_path = Rails.root.join("app", "assets", "images", "welcome.png").to_s
      @image = Vips::Image.new_from_file(welcome_path, access: :sequential)
      @image = @image.resize(WIDTH.to_f / @image.width, vscale: HEIGHT.to_f / @image.height)
    end
  end
end
