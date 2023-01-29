# frozen_string_literal: true

unless String.method_defined? "bg_black"
  class String
    # add string background colors
    #
    # ANSI color codes:
    #   \e => escape
    #   40 => color bg base
    #
    # For HTML coloring we use <kbd> tag instead of <span> to require monospace font.
    %w(black red green yellow blue purple cyan white).each_with_index do |color, i|
      define_method "bg_#{color}" do |*html|
        html[0] ? %Q|<kbd style="background:#{color}">#{self}</kbd>| : "\e[#{40 + i}m#{self}\e[0m"
      end
    end
  end
end

# only as comment - if we decide to remove 'awesome_print'
unless String.method_defined? "black"
  class String
    # add string colors
    #
    # ANSI color codes:
    #   \e => escape
    #   1;30 => color base
    #
    # For HTML coloring we use <kbd> tag instead of <span> to require monospace font.
    %w(gray red green yellow blue purple cyan white).each_with_index do |color, i|
      define_method color do |*html|
        html[0] ? %Q|<kbd style="color:#{color}">#{self}</kbd>| : "\e[1;#{30 + i}m#{self}\e[0m"
      end

      define_method "#{color}ish" do |*html|
        html[0] ? %Q|<kbd style="color:#{color}">#{self}</kbd>| : "\e[0;#{30 + i}m#{self}\e[0m"
      end
    end

    alias :black :grayish
    alias :pale  :whiteish
  end
end