CREATE DATABASE HospitalDB;
USE HospitalDB;

CREATE TABLE Patients (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    Full_Name VARCHAR(100),
    Phone VARCHAR(20),
    Age INT,
    Address VARCHAR(255)
);

DELIMITER //
CREATE PROCEDURE SeedPatients()
BEGIN
    DECLARE i INT DEFAULT 1;
    SET AUTOCOMMIT = 0;
    WHILE i <= 500000 DO
        INSERT INTO Patients (Full_Name, Phone, Age, Address)
        VALUES (CONCAT('Patient ', i), CONCAT('090', i), FLOOR(RAND()*100), 'Ho Chi Minh City');
        
        IF (i % 10000 = 0) THEN 
            COMMIT;
        END IF;
        
        SET i = i + 1;
    END WHILE;
    COMMIT;
    SET AUTOCOMMIT = 1;
END //
DELIMITER ;

CALL SeedPatients();