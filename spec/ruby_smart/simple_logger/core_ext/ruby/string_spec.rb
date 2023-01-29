# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'String extensions' do
  %w(black red green yellow blue purple cyan white).each_with_index do |color, i|
    it "should have #{color} background" do
      expect(color.to_s.send("bg_#{color}")).to eq("\e[#{40 + i}m#{color}\e[0m")
      expect(color.to_s.send("bg_#{color}", true)).to include "background:#{color}"
    end

    it "should have #{color}" do
      if color == 'black'
        expect(color.to_s.send(color)).to eq("\e[0;#{30 + i}m#{color}\e[0m")
        expect(color.to_s.send(color, true)).to include "color:gray"
      else
        expect(color.to_s.send(color)).to eq("\e[1;#{30 + i}m#{color}\e[0m")
        expect(color.to_s.send(color, true)).to include "color:#{color}"
      end
    end
  end
end