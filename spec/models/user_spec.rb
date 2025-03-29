require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#enums' do
    context 'gender' do
      it do
        expected = {"male"=>1, "female"=>2}
        expect(User.genders).to eq expected
      end
    end
  end
end
