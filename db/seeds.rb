(1..100).each do |i|
  puts "Creating user #{i}"
  User.create!(
    id: i,
    name: "User #{i}",
    email: "user#{i}@nal.vn",
    password: "password",
    gender: rand(1..2)
  )
end