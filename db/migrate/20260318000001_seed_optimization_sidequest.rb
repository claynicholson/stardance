class SeedOptimizationSidequest < ActiveRecord::Migration[8.1]
  class Sidequest < ActiveRecord::Base
    self.table_name = "sidequests"
  end

  def up
    return unless table_exists?(:sidequests)
    Sidequest.find_or_create_by!(slug: "optimization") do |sq|
      sq.title = "Optimization"
      sq.description = "Build and ship a project for the Optimization sidequest to unlock Optimization prizes in the shop."
    end
  end

  def down
    return unless table_exists?(:sidequests)
    Sidequest.find_by(slug: "optimization")&.destroy
  end
end
