module OgImage
  class Home < Base
    PREVIEWS = {
      "default" => -> { new }
    }.freeze

    STREAK_PATH = Rails.root.join("app", "assets", "images", "landing", "how-this-works", "colorful-streak.png").to_s
    EARTH_PATH = Rails.root.join("app", "assets", "images", "landing", "hero", "earth.png").to_s

    def render
      create_stardance_canvas
      place_image(STREAK_PATH, x: -60, y: -60, width: 800, height: 450, cover: false) if File.exist?(STREAK_PATH)
      draw_diagonal_scrim(opacity: 0.55)
      place_image(EARTH_PATH, x: -50, y: -70, width: 280, height: 280, gravity: "SouthWest", cover: false) if File.exist?(EARTH_PATH)
      place_star_character(x: 80, y: 80, width: 280, height: 280, gravity: "NorthEast")
      place_stardance_logo(x: 80, y: 80, width: 420, height: 120)
      draw_tagline
      draw_subtitle
    end

    private

    def draw_tagline
      draw_soft_shadow("Make projects. Get prizes.", x: 80, y: 280, size: 72, font: title_font_name, radius: 8, opacity: 0.6)
      draw_glowing_text(
        "Make projects. Get prizes.",
        x: 80, y: 280, size: 72,
        color: "#fffcf4", glow_color: "#ebb7ff",
        glow_radius: 10, glow_opacity: 0.4,
        font: title_font_name
      )
    end

    def draw_subtitle
      draw_soft_shadow("A free summer program for teens 13-18. By Hack Club.", x: 80, y: 380, size: 30, radius: 4, opacity: 0.5)
      draw_text("A free summer program for teens 13-18. By Hack Club.", x: 80, y: 380, size: 30, color: "#95dbff")
    end
  end
end
