require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { User.new(username: 'john_doe', email: 'john@example.com', password: 'password123', gender: 'male') }

  describe 'validations' do
    it 'should be valid with all required attributes' do
      expect(user).to be_valid
    end

    it 'should be invalid without a username' do
      user.username = nil
      expect(user).not_to be_valid
      expect(user.errors[:username]).to include("can't be blank")
    end

    it 'should be invalid with a duplicate username' do
      User.create!(username: 'john_doe', email: 'john@example.com', password: 'password123', gender: 'male')
      duplicate_user = User.new(username: 'john_doe', email: 'jane@example.com', password: 'password456', gender: 'female')
      expect(duplicate_user).not_to be_valid
      expect(duplicate_user.errors[:username]).to include('has already been taken')
    end
  end

  describe 'has_secure_password' do
    it 'should allow authentication with correct password' do
      saved_user = User.create!(username: 'john_doe', email: 'john@example.com', password: 'password123', gender: 'male')
      expect(saved_user.authenticate('password123')).to eq(saved_user)
    end

    it 'should reject authentication with incorrect password' do
      saved_user = User.create!(username: 'john_doe', email: 'john@example.com', password: 'password123', gender: 'male')
      expect(saved_user.authenticate('wrong_password')).to be_falsey
    end

    it 'should be invalid without a password' do
      user.password = nil
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end
  end

  describe 'gender enum' do
    it 'should accept male as a valid gender' do
      user.gender = 'male'
      expect(user).to be_valid
      expect(user.gender).to eq('male')
    end

    it 'should accept female as a valid gender' do
      user.gender = 'female'
      expect(user).to be_valid
      expect(user.gender).to eq('female')
    end
  end
end
