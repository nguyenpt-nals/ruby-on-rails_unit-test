FactoryBot.define do
  factory :order do
    user_id { 123 }
    type { 'A' }
    amount { 100 }
    flag { false }
    status { :new_order }
    priority { :low }
  end
end
