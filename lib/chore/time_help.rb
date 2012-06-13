module Chore
  module TimeHelp
    # Show stuff like "7 weeks, 3 days, 4 hours" instead of 
    # 13252363477 seconds since epoch
    def self.elapsed_human_time seconds
      remaining_ticks = seconds
      human_text = ""

      [[60,:seconds],[60,:minutes],[24,:hours],[7, :days]].each do |ticks, unit|
        above = remaining_ticks / ticks
        below = remaining_ticks % ticks

        if below != 0
          unit = unit[0..-2] if below == 1
          human_text = "#{below} #{unit} " + human_text
        end

        remaining_ticks = above
        if above == 0
          break
          end
      end
      human_text.strip
    end
  end
end
