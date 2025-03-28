# Ruby on Rails Unit Test với RSpec

Chào mừng bạn đến với repo này! Đây là hướng dẫn để cài đặt và chạy môi trường unit test sử dụng RSpec trong một dự án Ruby on Rails.

## Yêu cầu trước khi bắt đầu
- Đã cài đặt Docker

## Hướng dẫn cài đặt

### 1. Clone repository
Clone repo này về máy của bạn bằng lệnh sau:

```bash
git clone https://github.com/loctx-nals/ruby-on-rails_unit-test.git
cd ruby-on-rails_unit-test
```

### 2. Build environment
```bash
docker-compose up --build
docker exec -it ruby-on-rails_unit-test_web_1 bash
```

### 3. Create database
Tạo, migrate và seed cơ sở dữ liệu:
```bash
rails db:create
rails db:migrate
rails db:seed
```

### 4. Install dependencies
Sử dụng gem rspec-rails để viết unit test, thông tin chi tiết tại https://github.com/rspec/rspec-rails

### 5. Chạy các unit test
Để chạy toàn bộ test suite:

```bash
rspec
```

Hoặc chạy một file test cụ thể:

```bash
rspec spec/path/to/your_test_file.rb
```

### 6. Cài thêm các gem hỗ trợ cho quá trình viết unit test
- faker
- factory_bot
- simplecov
- ...
