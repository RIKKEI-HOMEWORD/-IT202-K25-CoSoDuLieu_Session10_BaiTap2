-- =====================================================
-- BÀI TẬP: TỐI ƯU HIỆU NĂNG TIẾP NHẬN BỆNH NHÂN
-- =====================================================

-- =====================================================
-- TẠO DATABASE
-- =====================================================
CREATE DATABASE IF NOT EXISTS hospital_performance_db;
USE hospital_performance_db;
-- =====================================================
-- TẠO BẢNG PATIENTS
-- =====================================================
CREATE TABLE Patients (
    Patient_ID INT PRIMARY KEY AUTO_INCREMENT,
    Full_Name VARCHAR(100),
    Phone VARCHAR(20),
    Age INT,
    Address VARCHAR(255)
);
-- =====================================================
-- TẠO PROCEDURE SINH 500.000 DỮ LIỆU MẪU
-- =====================================================
DELIMITER //

CREATE PROCEDURE SeedPatients()
BEGIN
    DECLARE i INT DEFAULT 1;

    WHILE i <= 500000 DO

        INSERT INTO Patients (
            Full_Name,
            Phone,
            Age,
            Address
        )
        VALUES (
            CONCAT('Patient ', i),
            CONCAT('090', i),
            FLOOR(RAND() * 100),
            'Ho Chi Minh City'
        );

        SET i = i + 1;

    END WHILE;

END //

DELIMITER ;
-- =====================================================
-- GỌI PROCEDURE ĐỂ NẠP 500.000 DÒNG DỮ LIỆU
-- =====================================================
CALL SeedPatients();
-- =====================================================
-- KIỂM TRA SỐ LƯỢNG DỮ LIỆU
-- =====================================================
SELECT COUNT(*) AS total_patients
FROM Patients;
-- =====================================================
-- TRUY VẤN TRƯỚC KHI ĐÁNH INDEX
-- =====================================================
SELECT *
FROM Patients
WHERE Phone = '090300000';
-- =====================================================
-- PHÂN TÍCH CÁCH MYSQL HOẠT ĐỘNG
-- =====================================================
-- EXPLAIN cho biết Database xử lý truy vấn như thế nào.
--
-- Kết quả trước khi có INDEX:
--   type = ALL
--
-- Điều này nghĩa là MySQL phải quét toàn bộ bảng.
-- Đây là nguyên nhân gây chậm hệ thống.
-- =====================================================
EXPLAIN
SELECT *
FROM Patients
WHERE Phone = '090300000';
-- =====================================================
-- TẠO INDEX CHO CỘT PHONE
-- =====================================================
CREATE INDEX idx_phone
ON Patients(Phone);
-- =====================================================
-- TRUY VẤN SAU KHI ĐÁNH INDEX
-- =====================================================
SELECT *
FROM Patients
WHERE Phone = '090300000';
-- =====================================================
-- PHÂN TÍCH TRUY VẤN SAU KHI CÓ INDEX
-- =====================================================
-- Kết quả EXPLAIN lúc này:
--   type = ref hoặc const
--
-- Điều này cho thấy MySQL đã sử dụng INDEX
-- thay vì Full Table Scan.
--
-- rows được quét cũng giảm cực mạnh.
-- =====================================================
EXPLAIN
SELECT *
FROM Patients
WHERE Phone = '090300000';
-- =====================================================
-- ĐO HIỆU NĂNG INSERT KHI KHÔNG CÓ INDEX
-- =====================================================
-- Ý tưởng:
-- Xóa INDEX trước,
-- sau đó thêm liên tục 1000 dòng dữ liệu.
--
-- Vì không cần cập nhật INDEX,
-- INSERT sẽ nhanh hơn.
-- =====================================================
DROP INDEX idx_phone
ON Patients;
-- =====================================================
-- GHI LẠI THỜI GIAN BẮT ĐẦU
-- =====================================================
SET @start_no_index = NOW();
-- =====================================================
-- THÊM 1000 DÒNG DỮ LIỆU
-- =====================================================
DELIMITER //

CREATE PROCEDURE InsertWithoutIndex()
BEGIN

    DECLARE i INT DEFAULT 1;

    WHILE i <= 1000 DO

        INSERT INTO Patients (
            Full_Name,
            Phone,
            Age,
            Address
        )
        VALUES (
            CONCAT('New Patient ', i),
            CONCAT('099', i),
            FLOOR(RAND() * 100),
            'Ho Chi Minh City'
        );

        SET i = i + 1;

    END WHILE;

END //

DELIMITER ;

CALL InsertWithoutIndex();
-- =====================================================
-- GHI LẠI THỜI GIAN KẾT THÚC
-- =====================================================
SET @end_no_index = NOW();
-- =====================================================
-- TÍNH THỜI GIAN THỰC THI
-- =====================================================
SELECT TIMESTAMPDIFF(MICROSECOND,
       @start_no_index,
       @end_no_index) / 1000000
       AS insert_time_without_index_seconds;
-- =====================================================
-- TẠO LẠI INDEX
-- =====================================================
CREATE INDEX idx_phone
ON Patients(Phone);
-- =====================================================
-- ĐO HIỆU NĂNG INSERT KHI CÓ INDEX
-- =====================================================
SET @start_with_index = NOW();

DELIMITER //

CREATE PROCEDURE InsertWithIndex()
BEGIN

    DECLARE i INT DEFAULT 1;

    WHILE i <= 1000 DO

        INSERT INTO Patients (
            Full_Name,
            Phone,
            Age,
            Address
        )
        VALUES (
            CONCAT('Indexed Patient ', i),
            CONCAT('088', i),
            FLOOR(RAND() * 100),
            'Ho Chi Minh City'
        );

        SET i = i + 1;

    END WHILE;

END //

DELIMITER ;

CALL InsertWithIndex();

SET @end_with_index = NOW();

-- =====================================================
-- TÍNH THỜI GIAN INSERT KHI CÓ INDEX
-- =====================================================
SELECT TIMESTAMPDIFF(MICROSECOND,
       @start_with_index,
       @end_with_index) / 1000000
       AS insert_time_with_index_seconds;
-- =====================================================
-- TỔNG HỢP NHẬN XÉT
-- =====================================================
-- 1. INDEX giúp SELECT nhanh hơn rất nhiều.
--
-- 2. Trước khi có INDEX:
--      MySQL phải quét toàn bộ bảng.
--      => Truy vấn chậm.
--
-- 3. Sau khi có INDEX:
--      MySQL tìm trực tiếp dữ liệu cần thiết.
--      => Truy vấn nhanh hơn rõ rệt.
--
-- 4. Tuy nhiên INDEX tạo ra "trade-off":
--      + SELECT nhanh hơn
--      + INSERT / UPDATE chậm hơn
--
-- 5. Nguyên nhân:
--      Mỗi lần ghi dữ liệu,
--      MySQL phải cập nhật thêm INDEX.
--
-- 6. Trong hệ thống bệnh viện thực tế:
--      INDEX rất cần thiết cho các cột:
--          - Phone
--          - CCCD
--          - Email
--          - Mã bệnh nhân
--
--      vì đây là các cột thường xuyên được tra cứu.
--
-- 7. Kết luận:
--      INDEX là công cụ cực kỳ quan trọng
--      để tối ưu hiệu năng đọc dữ liệu
--      trên các hệ thống lớn.
-- =====================================================