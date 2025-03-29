class User < ApplicationRecord
  has_secure_password

  enum gender: { male: 1, female: 2 }
end
