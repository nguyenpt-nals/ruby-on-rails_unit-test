require 'rails_helper'
include CalculateModule

RSpec.describe CalculateModule, type: :service do
  describe '#sum' do
    it 'returns the sum of two numbers' do
      expect(sum(2, 3)).to eq(5)
    end
  end

  describe '#calculate_age' do
    it 'returns a message for minors' do
      expect(calculate_age(10)).to eq("You are a minor.")
      expect(calculate_age(17)).to eq("You are a minor.")
    end

    it 'returns a message for adults' do
      expect(calculate_age(18)).to eq("You are an adult.")
      expect(calculate_age(45)).to eq("You are an adult.")
      expect(calculate_age(64)).to eq("You are an adult.")
    end

    it 'returns a message for senior citizens' do
      expect(calculate_age(65)).to eq("You are a senior citizen.")
      expect(calculate_age(70)).to eq("You are a senior citizen.")
    end
  end
end
