# Unit Test Checklist

## 1. **General Structure**
### 1.1 Test Case Pattern
- **Test Case Format**:
  - **Test Case Title**: Tên test case, mô tả ngắn gọn về mục tiêu của test.
  - **Preconditions**: Các điều kiện cần thiết trước khi chạy test (data, trạng thái hệ thống,...).
  - **Test Steps**: Các bước thực hiện test chi tiết.
  - **Expected Result**: Kết quả mong đợi sau khi thực hiện test case.

### 1.2 Categories of Test Cases
- **Positive Test Cases**: Kiểm tra các tình huống hệ thống hoạt động đúng với dữ liệu hợp lệ.
- **Negative Test Cases**: Kiểm tra các tình huống khi hệ thống gặp lỗi hoặc dữ liệu không hợp lệ.
- **Edge Cases**: Kiểm tra các trường hợp biên, dữ liệu cực trị hoặc các tình huống bất thường.
- **Exception Handling**: Kiểm tra các tình huống xảy ra lỗi, exception được xử lý đúng.
- **Performance**: Kiểm tra hiệu suất, tốc độ xử lý của hệ thống trong các tình huống khối lượng lớn.

---

## 2. **Test Case Details**

### ✅ **Test Case 1: process_orders(user_id)**
- **Preconditions**:
  - Có ít nhất một đơn hàng hợp lệ trong hệ thống.
- **Test Steps**:
  - Gọi `process_orders(user_id)`.
- **Expected Result**:
  - Trả về `true` nếu tất cả các đơn hàng được xử lý thành công.

---

### ✅ **Test Case 2: process_order(order, user_id)**
#### **2.1 Khi order type là 'A'**
- **Preconditions**:
  - `order.type = 'A'` và đơn hàng có amount hợp lệ.
- **Test Steps**:
  - Gọi `process_order(order, user_id)`.
- **Expected Result**:
  - Nếu CSV tạo thành công, cập nhật `order.status = 'exported'`.

#### **2.2 Khi order type là 'B'**
- **Preconditions**:
  - `order.type = 'B'` và API trả về kết quả hợp lệ.
- **Test Steps**:
  - Gọi `process_order(order, user_id)`.
- **Expected Result**:
  - Cập nhật trạng thái của `order` dựa trên dữ liệu trả về từ API (processed, pending, error).

#### **2.3 Khi order type không xác định**
- **Preconditions**:
  - `order.type` không thuộc loại `A`, `B`, `C`.
- **Test Steps**:
  - Gọi `process_order(order, user_id)`.
- **Expected Result**:
  - Cập nhật trạng thái `order.status = 'unknown_type'`.

---

### ✅ **Test Case 3: update_priority(order)**
- **Preconditions**:
  - `order.amount` có giá trị khác nhau (lớn hơn và nhỏ hơn 200).
- **Test Steps**:
  - Gọi `update_priority(order)`.
- **Expected Result**:
  - Nếu `order.amount > 200`, cập nhật `order.priority = 'high'`.
  - Nếu `order.amount <= 200`, cập nhật `order.priority = 'low'`.

---

### ✅ **Test Case 4: save_order(order)**
- **Preconditions**:
  - Đơn hàng có trạng thái hợp lệ và chưa lưu vào cơ sở dữ liệu.
- **Test Steps**:
  - Gọi `save_order(order)`.
- **Expected Result**:
  - Đơn hàng được lưu mà không có lỗi, trạng thái không thay đổi thành `'db_error'`.

#### **4.1 Trường hợp Database exception**
- **Preconditions**:
  - Gây ra exception trong quá trình lưu trữ (`DatabaseException`).
- **Test Steps**:
  - Gọi `save_order(order)`.
- **Expected Result**:
  - Đơn hàng sẽ có `status = 'db_error'`.

---

### ✅ **Test Case 5: csv_generate(order, user_id)**
- **Preconditions**:
  - `order.type = 'A'`, `csv_generate` được gọi với các tham số hợp lệ.
- **Test Steps**:
  - Gọi `csv_generate(order, user_id)`.
- **Expected Result**:
  - Tạo file CSV với các dữ liệu của `order`, bao gồm các trường như ID, Type, Amount, Flag, Status, Priority.

#### **5.1 Trường hợp đơn hàng có giá trị cao**
- **Preconditions**:
  - `order.amount > 150`.
- **Test Steps**:
  - Gọi `csv_generate(order, user_id)`.
- **Expected Result**:
  - CSV bao gồm dòng `['', '', '', '', 'Note', 'High value order']`.

---
