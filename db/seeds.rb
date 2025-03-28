(1..100).each do |i|
  User.find_or_create_by!(id: i) do |user|
    user.username = "username#{i}"
    user.email = "email#{i}@nal.vn"
    user.gender = rand(0..1)
  end
end
