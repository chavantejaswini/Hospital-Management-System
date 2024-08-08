--USE AdventureWorks2008R2;

--DROP DATABASE Group17;

CREATE DATABASE Group17

USE Group17

CREATE TABLE Pharmacy (
  pharmacy_id VARCHAR(10) NOT NULL PRIMARY KEY,
  pharmacy_name VARCHAR(45) NOT NULL,
  streetname VARCHAR(45),
  city VARCHAR(45),
  zipcode VARCHAR(45),
  country VARCHAR(45),
  phone VARCHAR(45)
  );
--DROP TABLE Insurance
 CREATE TABLE Insurance (
  insurance_id VARCHAR(10) NOT NULL PRIMARY KEY,
  provider_name VARCHAR(45) NOT NULL,
  policy_number VARCHAR(45) NOT NULL,
  copay_percentage INT NOT NULL,
  );
--DROP TABLE Patient
 CREATE TABLE Patient (
  patient_id VARCHAR(10) NOT NULL PRIMARY KEY,
  firstname VARCHAR(45) NOT NULL,
  lastname VARCHAR(45) NOT NULL,
  age INT,
  gender VARCHAR(45),
  date_of_birth DATE,
  streetname VARCHAR(45),
  city VARCHAR(45),
  zipcode VARCHAR(45),
  country VARCHAR(45),
  phone VARCHAR(45),
  email VARCHAR(45),
  emergency_contact_name VARCHAR(45) NOT NULL,
  emergency_contact VARCHAR(45) NOT NULL,
  emergency_contact_relationship VARCHAR(45),
  pharmacy_id VARCHAR(10) NOT NULL REFERENCES Pharmacy(pharmacy_id),
  insurance_id VARCHAR(10) NOT NULL REFERENCES Insurance(insurance_id), 
  );
 
 CREATE TABLE Department (
  department_id VARCHAR(10) NOT NULL PRIMARY KEY,
  name VARCHAR(45) NOT NULL,
  phone VARCHAR(45)
  );
 
 
 CREATE TABLE Staff (
  staff_id VARCHAR(10) NOT NULL PRIMARY KEY,
  firstname VARCHAR(45) NOT NULL,
  lastname VARCHAR(45) NULL,
  "role" VARCHAR(45) NOT NULL,
  email VARCHAR(45),
  phone VARCHAR(45),
  streetname VARCHAR(45),
  city VARCHAR(45),
  zipcode VARCHAR(45),
  country VARCHAR(45),
  department_id VARCHAR(10) NOT NULL REFERENCES Department(department_id)
  );
 
CREATE TABLE Appointment (
  appointment_id VARCHAR(10) NOT NULL PRIMARY KEY,
  "date" DATE NOT NULL,
  "time" TIME NOT NULL,
  patient_id VARCHAR(10) NOT NULL REFERENCES Patient(patient_id),
  doctor_id VARCHAR(10) NOT NULL REFERENCES Staff(staff_id),
  purpose VARCHAR(45)
  );

--DROP TABLE Payroll
CREATE TABLE Payroll (
  staff_id VARCHAR(10) NOT NULL PRIMARY KEY REFERENCES Staff(staff_id),
  account_number VARCHAR(45) NOT NULL,
  account_type VARCHAR(45),
  salary VARBINARY (250)
  );

CREATE TABLE Doctor (
  doctor_id VARCHAR(10) NOT NULL PRIMARY KEY REFERENCES Staff(staff_id),
  specialization VARCHAR(45) NOT NULL,
  surgery_count INT,
  surgery_type VARCHAR(45)
  );

CREATE TABLE Nurse (
  nurse_id VARCHAR(10) NOT NULL PRIMARY KEY REFERENCES Staff(staff_id),
  qualifications VARCHAR(45),
  "position" VARCHAR(45) NOT NULL,
  years_of_experience INT
  );

 CREATE TABLE Equipment (
  equipment_id VARCHAR(10) NOT NULL PRIMARY KEY,
  name VARCHAR(45) NOT NULL,
  "type" VARCHAR(45),
  status VARCHAR(45)
  );

CREATE TABLE Room (
  room_id VARCHAR(10) NOT NULL PRIMARY KEY,
  room_number VARCHAR(45) NOT NULL,
  room_type VARCHAR(45),
  status VARCHAR(45),
  equipment_id VARCHAR(10) NOT NULL REFERENCES Equipment(equipment_id)
  );

 CREATE TABLE Medical_Record (
  record_id VARCHAR(10) NOT NULL PRIMARY KEY,
  diagnosis VARCHAR(45),
  room_id VARCHAR(10) NOT NULL REFERENCES Room(room_id),
  appointment_id VARCHAR(10) NOT NULL REFERENCES Appointment(appointment_id)
  );

CREATE TABLE Medication (
  medication_id VARCHAR(10) NOT NULL PRIMARY KEY,
  name VARCHAR(45) NOT NULL,
  over_the_counter VARCHAR(45)
  );

CREATE TABLE Prescription (
  record_id VARCHAR(10) NOT NULL REFERENCES Medical_Record(record_id),
  medication_id VARCHAR(10) NOT NULL REFERENCES Medication(medication_id)
  PRIMARY KEY (record_id, medication_id)
  );
 
 
CREATE TABLE Labratory_Tests (
  test_id VARCHAR(10) NOT NULL PRIMARY KEY,
  name VARCHAR(45) NOT NULL,
  cost INT,
  "type" VARCHAR(45)
  );

--DROP TABLE Billing;
CREATE TABLE Billing (
  billing_id VARCHAR(10) NOT NULL PRIMARY KEY,
  date_issued DATE,
  amount INT NOT NULL,
  status VARCHAR(45) NOT NULL,
  insurance_claim VARCHAR(45)
  );
 
--DROP TABLE Treatment;
CREATE TABLE Treatment (
  treatment_id VARCHAR(10) NOT NULL PRIMARY KEY,
  record_id VARCHAR(10) NOT NULL REFERENCES Medical_Record(record_id),
  start_date DATE,
  description VARCHAR(45),
  billing_id VARCHAR(10) NOT NULL REFERENCES Billing(billing_id),
  test_id VARCHAR(10) NOT NULL REFERENCES Labratory_Tests(test_id)
  );
 
--Encryption
-- Creating DMK
CREATE MASTER KEY
ENCRYPTION BY PASSWORD = 'Group@17';

-- Creating certificate to protecting the symmetric key
CREATE CERTIFICATE TestCertificate
WITH SUBJECT = 'Hospital Test Certificate',
EXPIRY_DATE = '2027-05-31';

-- Creating symmetric key to encrypting the data
CREATE SYMMETRIC KEY TestSymmetricKey
WITH ALGORITHM = AES_128
ENCRYPTION BY CERTIFICATE TestCertificate;

-- Opening symmetric key
OPEN SYMMETRIC KEY TestSymmetricKey
DECRYPTION BY CERTIFICATE TestCertificate;

--VIEWS

--VIEW1
--High risk bills which are unpaid above $300
CREATE VIEW HighRiskBills 
AS
SELECT billing_id
, amount
, insurance_claim 
FROM Billing
WHERE (amount > 300) and (status = 'Unpaid');

--VIEW2
--Count of Dcotors and Nurses per Department
--DROP VIEW StaffperDepartment;
CREATE VIEW StaffperDepartment 
AS
WITH Doctor_Count as (
SELECT d.name AS Department
, COUNT(s.staff_id) AS Count_of_Doctors
FROM Staff s
RIGHT JOIN
Department d ON s.department_id = d.department_id AND s.role = 'Doctor'
GROUP BY d.department_id, d.name),
Nurse_Count as (
SELECT d.name AS Department
, COUNT(s.staff_id) AS Count_of_Nurse
FROM Staff s
RIGHT JOIN
Department d ON s.department_id = d.department_id AND s.role = 'Nurse'
GROUP BY d.department_id, d.name)
SELECT dc.Department, dc.Count_of_Doctors, ns.Count_of_Nurse
FROM Doctor_Count dc
JOIN Nurse_Count ns
ON dc.Department = ns.Department


--View3
-- View for patient appointments
CREATE VIEW PatientAppointments 
AS
SELECT p.firstname
, p.lastname
, a.date
, a.time
, a.purpose
FROM Patient p
JOIN Appointment a ON p.patient_id = a.patient_id;



--View4
-- View for doctor specialties and their patient count
CREATE VIEW DoctorSpecialties AS
SELECT d.specialization, COUNT(a.appointment_id) AS patient_count
FROM Doctor d
JOIN Appointment a ON d.doctor_id = a.doctor_id
GROUP BY d.specialization;


-- Computed Column based on a function
--Calculating copay amount based on the insurance copay percentage
--DROP FUNCTION CalculateCopayAmount;
CREATE FUNCTION CalculateCopayAmount (@billing_id VARCHAR(10))
RETURNS DECIMAL(10, 2)
AS
BEGIN
	DECLARE @copay_percentage INT;
    DECLARE @billing_amount INT;
    DECLARE @insurance_claim VARCHAR(45);
   	DECLARE @copay_amount DECIMAL(10,2) = 0;
   
	SELECT @billing_amount = b.amount , @insurance_claim = b.insurance_claim, @copay_percentage = i.copay_percentage
	FROM Billing b
	JOIN Treatment t 
	ON b.billing_id = t.billing_id 
	JOIN Medical_record m
	ON t.record_id = m.record_id 
	JOIN Appointment a 
	ON m.appointment_id = a.appointment_id 
	JOIN Patient p
	ON a.patient_id = p.patient_id 
	JOIN Insurance i
	ON p.insurance_id = i.insurance_id
	WHERE b.billing_id = @billing_id;
	
	IF @insurance_claim = 'yes'
    BEGIN
    	SET @copay_amount = @billing_amount * @copay_percentage / 100.0;
    END
    ELSE
    BEGIN
    	SET @copay_amount = 0;
    END
    
    RETURN @copay_amount;    
END;

ALTER TABLE Billing
ADD CopayAmount AS dbo.CalculateCopayAmount(billing_id);



--Table-level CHECK Constraints based on a function


--Checking if no.of medications per record is more than 5
CREATE FUNCTION PrescriptionCount(@record_id VARCHAR)
RETURNS SMALLINT
AS
BEGIN
DECLARE @Count SMALLINT = 0;
SELECT @Count = COUNT(record_id)
FROM Prescription
WHERE record_id = @record_id;
RETURN @Count
END;
ALTER TABLE Prescription ADD CONSTRAINT MedicationLimit CHECK (dbo.PrescriptionCount(record_id)
< 6);

--Checking if no.of appointments per day is more than 3
CREATE FUNCTION AppointmentCount(@patient_id VARCHAR)
RETURNS SMALLINT
AS
BEGIN
DECLARE @Count SMALLINT = 0;
SELECT @Count = COUNT(appointment_id)
FROM Appointment
WHERE patient_id = @patient_id;
RETURN @Count
END;
ALTER TABLE Appointment ADD CONSTRAINT AppointmentLimit CHECK (dbo.AppointmentCount(patient_id)
< 4);


--Laboratory table 
INSERT INTO Labratory_Tests (test_id, name, cost, "type") VALUES
('LT123', 'Cardiac Stress Test', 220, 'Cardiac'),
('LT124', 'Bone Density Scan', 190, 'Imaging'),
('LT125', 'EEG', 180, 'Neurological'),
('LT126', 'Spirometry', 160, 'Pulmonary'),
('LT127', 'Developmental Screening', 140, 'Pediatric'),
('LT128', 'Skin Allergy Test', 90, 'Dermatology'),
('LT129', 'Visual Field Test', 110, 'Ophthalmology'),
('LT130', 'Tumor Marker', 230, 'Oncology'),
('LT131', 'Colonoscopy', 350, 'Gastroenterology'),
('LT132', 'Urinary Tract Imaging', 210, 'Urology'),
('LT133', 'Prostate-Specific Antigen (PSA) Test', 200, 'Urology'),
('LT134', 'Upper Endoscopy', 400, 'Gastroenterology');


--Insurance table: 
INSERT INTO Insurance (insurance_id , provider_name, policy_number, copay_percentage) VALUES
('I21', 'UnitedHealthcare', 'POL1001', 20),
('I22', 'Blue Cross Blue Shield', 'POL2002', 15),
('I23', 'Aetna', 'POL3003', 10),
('I24', 'Cigna', 'POL4004', 25),
('I25', 'Humana', 'POL5005', 30),
('I26', 'Anthem', 'POL6006', 5),
('I27', 'Kaiser Permanente', 'POL7007', 20),
('I28', 'Centene', 'POL8008', 15),
('I29', 'Molina Healthcare', 'POL9009', 10),
('I30', 'WellCare', 'POL1010', 25),
('I31', 'CareFirst', 'POL1111', 30),
('I32', 'Highmark', 'POL1212', 5);

--Pharmacy table: 
INSERT INTO Pharmacy (pharmacy_id, pharmacy_name, streetname, city, zipcode, country, phone) VALUES
('P01', 'Walgreens', '123 Main St', 'Newyork', '10001', 'USA', '1234567890'),
('P02', 'CVS Pharmacy', '456 Oak St', 'Newjersey', '20002', 'USA', '2345678901'),
('P03', 'Rite Aid', '789 Pine St', 'Boston', '30003', 'USA', '3456789012'),
('P04', 'Walmart Pharmacy', '321 Elm St', 'Denver', '40004', 'USA', '4567890123'),
('P05', 'Kroger Pharmacy', '654 Maple St', 'Nashville', '50005', 'USA', '5678901234'),
('P06', 'Costco Pharmacy', '987 Willow St', 'Dallas', '60006', 'USA', '6789012345'),
('P07', 'Target Pharmacy', '345 Birch St', 'Jacksonvile', '70007', 'USA', '7890123456'),
('P08', 'Publix Pharmacy', '678 Aspen St', 'Chiacgo', '80008', 'USA', '8901234567'),
('P09', 'Safeway Pharmacy', '901 Cedar St', 'Washington', '90009', 'USA', '9012345678'),
('P010', 'Sam’s Club Pharmacy', '234 Spruce St', 'Baltimore', '10010', 'USA', '0123456789'),
('P011', 'Giant Pharmacy', '567 Redwood St', 'Seattle', '11011', 'USA', '1234509876'),
('P012', 'Albertsons Pharmacy', '890 Sequoia St', 'Austin', '12012', 'USA', '2345610987');

--Equipment table: 
INSERT INTO Equipment (equipment_id, name, "type", status) VALUES
('E123', 'ECG Machine', 'Cardiac', 'Available'),
('E223', 'X-Ray Machine', 'Imaging', 'Maintenance'),
('E323', 'MRI Machine', 'Imaging', 'Maintenance'),
('E423', 'CT Scanner', 'Imaging', 'Available'),
('E523', 'Ultrasound Machine', 'Imaging', 'Available'),
('E623', 'Blood Pressure Monitor', 'Monitoring', 'Available'),
('E723', 'Defibrillator', 'Emergency', 'Available'),
('E823', 'Ventilator', 'Respiratory', 'Available'),
('E923', 'Anesthesia Machine', 'Surgical', 'Maintenance'),
('E1023', 'Operating Table', 'Surgical', 'Available'),
('E1123', 'Sterilizer', 'Surgical', 'Available'),
('E1223', 'Wheelchair', 'Mobility', 'Available');

--Room table: 
INSERT INTO Room (room_id, room_number, room_type, status, equipment_id) VALUES
('Room10', '101', 'Single', 'Occupied', 'E123'),
('Room20', '102', 'Double', 'Vacant', 'E1223'),
('Room30', '103', 'Single', 'Occupied', 'E423'),
('Room40', '104', 'Double', 'Vacant', 'E423'),
('Room50', '105', 'Single', 'Available', 'E523'),
('Room60', '106', 'Double', 'Occupied', 'E623'),
('Room70', '107', 'Single', 'Available', 'E723'),
('Room80', '108', 'Double', 'Occupied', 'E823'),
('Room90', '109', 'Single', 'Maintenance', 'E1123'),
('Room100', '110', 'Double', 'Available', 'E1023'),
('Room110', '111', 'Single', 'Occupied', 'E1123'),
('Room120', '112', 'Double', 'Vacant', 'E1223');

--Department table

INSERT INTO Department (department_id, name, phone) VALUES
('Dpt1', 'Cardiology', '800-123-4567'),
('Dpt2', 'Orthopedics', '800-234-5678'),
('Dpt3', 'Neurology', '800-345-6789'),
('Dpt4', 'Pediatrics', '800-456-7890'),
('Dpt5', 'Dermatology', '800-567-8901'),
('Dpt6', 'Ophthalmology', '800-678-9012'),
('Dpt7', 'Oncology', '800-789-0123'),
('Dpt8', 'Gastroenterology', '800-890-1234'),
('Dpt9', 'Urology', '800-901-2345'),
('Dpt10', 'ENT', '800-012-3456'),
('Dpt11', 'Pulmonology', '800-123-4567'),
('Dpt12', 'Psychiatry', '800-234-5678');


-- Staff Tablee
INSERT INTO Staff (staff_id, firstname, lastname, "role", email, phone, streetname, city, zipcode, country, department_id) VALUES
-- Doctors
('D001', 'John', 'Doe', 'Doctor', 'jdoe@example.com', '1234567890', '300 Park Ave', 'New York', '10001', 'USA', 'Dpt1'),
('D002', 'Jane', 'Smith', 'Doctor', 'jsmith@example.com', '2345678901', '456 Hollywood Blvd', 'Los Angeles', '90001', 'USA', 'Dpt2'),
('D003', 'Emily', 'Johnson', 'Doctor', 'ejohnson@example.com', '3456789012', '789 Lakeshore Dr', 'Chicago', '60007', 'USA', 'Dpt3'),
('D004', 'Michael', 'Brown', 'Doctor', 'mbrown@example.com', '4567890123', '321 Space Center Blvd', 'Houston', '77001', 'USA', 'Dpt1'),
('D005', 'Jessica', 'Davis', 'Doctor', 'jdavis@example.com', '5678901234', '654 Camelback Rd', 'Phoenix', '85001', 'USA', 'Dpt2'),
('D006', 'William', 'Wilson', 'Doctor', 'wwilson@example.com', '6789012345', '987 Broad St', 'Philadelphia', '19019', 'USA', 'Dpt11'),
('D007', 'Olivia', 'Martin', 'Doctor', 'omartin@example.com', '7890123456', '345 Quarry Rd', 'San Antonio', '78201', 'USA', 'Dpt4'),
('D008', 'James', 'Taylor', 'Doctor', 'jtaylor@example.com', '8901234567', '678 Gaslight Sq', 'San Diego', '92101', 'USA', 'Dpt5'),
('D009', 'Laura', 'Moore', 'Doctor', 'lmoore@example.com', '9012345678', '901 West End Blvd', 'Dallas', '75201', 'USA', 'Dpt6'),
('D010', 'David', 'Anderson', 'Doctor', 'danderson@example.com', '0123456789', '234 Peachtree St', 'San Jose', '95101', 'USA', 'Dpt7'),
('D0011', 'Sophia', 'Thomas', 'Doctor', 'sthomas@example.com', '1234509876', '567 King St', 'Austin', '73301', 'USA', 'Dpt8'),
('D0012', 'Daniel', 'Jackson', 'Doctor', 'djackson@example.com', '2345610987', '890 Ocean Ave', 'Jacksonville', '32099', 'USA', 'Dpt9'),
-- Nurses
('N51', 'Olivia', 'Martin', 'Nurse', 'omartin@example.com', '7890123456', '345 Quarry Rd', 'San Antonio', '78201', 'USA', 'Dpt2'),
('N52', 'James', 'Taylor', 'Nurse', 'jtaylor@example.com', '8901234567', '678 Gaslight Sq', 'San Diego', '92101', 'USA', 'Dpt3'),
('N53', 'Laura', 'Moore', 'Nurse', 'lmoore@example.com', '9012345678', '901 West End Blvd', 'Dallas', '75201', 'USA', 'Dpt4'),
('N54', 'David', 'Anderson', 'Nurse', 'danderson@example.com', '0123456789', '234 Peachtree St', 'San Jose', '95101', 'USA', 'Dpt6'),
('N55', 'Sophia', 'Thomas', 'Nurse', 'sthomas@example.com', '1234509876', '567 King St', 'Austin', '73301', 'USA', 'Dpt9'),
('N56', 'Daniel', 'Jackson', 'Nurse', 'djackson@example.com', '2345610987', '890 Ocean Ave', 'Jacksonville', '32099', 'USA', 'Dpt8'),
('N57', 'Alice', 'Wright', 'Nurse', 'awright@example.com', '3456721987', '123 Birch St', 'Memphis', '38101', 'USA', 'Dpt1'),
('N58', 'Mark', 'Johnson', 'Nurse', 'mjohnson@example.com', '4567832098', '234 Cedar Ln', 'Boston', '02101', 'USA', 'Dpt9'),
('N59', 'Natalie', 'Miller', 'Nurse', 'nmiller@example.com', '5678943219', '345 Daisy Dr', 'Seattle', '98101', 'USA', 'Dpt10'),
('N60', 'Luke', 'Evans', 'Nurse', 'levans@example.com', '6789054321', '456 Elm St', 'Denver', '80201', 'USA', 'Dpt11'),
('N61', 'Zoe', 'Taylor', 'Nurse', 'ztaylor@example.com', '7890165432', '567 Fern St', 'Baltimore', '21201', 'USA', 'Dpt12'),
('N62', 'Ethan', 'Brown', 'Nurse', 'ebrown@example.com', '8901276543', '678 Grove Ave', 'Atlanta', '30301', 'USA', 'Dpt2');


--Nurse table: 
INSERT INTO Nurse (nurse_id, qualifications, "position", years_of_experience) VALUES
('N51', 'BSN', 'Registered Nurse', 5),
('N52', 'ADN', 'Staff Nurse', 3),
('N53', 'BSN', 'Senior Nurse', 8),
('N54', 'MSN', 'Nurse Practitioner', 7),
('N55', 'ADN', 'Registered Nurse', 4),
('N56', 'BSN', 'Nurse Manager', 10),
('N57', 'MSN', 'Clinical Nurse Specialist', 6),
('N58', 'BSN', 'Staff Nurse', 2),
('N59', 'ADN', 'Registered Nurse', 5),
('N60', 'BSN', 'Senior Nurse', 9),
('N61', 'MSN', 'Nurse Practitioner', 7),
('N62', 'ADN', 'Nurse Manager', 11);

--Doctor table: 
INSERT INTO Doctor (doctor_id, specialization, surgery_count, surgery_type) VALUES
('D001', 'Cardiology', 50, 'Cardiac Surgery'),
('D002', 'Orthopedics', 40, 'Joint Replacement'),
('D003', 'Neurology', 30, 'Brain Surgery'),
('D004', 'Cardiology', 20, 'Cardiac Surgery'),
('D005', 'Orthopedics', 10, 'Joint Replacement'),
('D006', 'Pulmonology', 60, 'Lung Surgery'),
('D007', 'Pediatrics', 70, 'Pediatric Surgery'),
('D008', 'Dermatology', 80, 'Cosmetic Surgery'),
('D009', 'Ophthalmology', 90, 'Cataract Surgery'),
('D010', 'Oncology', 100, 'Cancer Surgery'),
('D0011', 'Gastroenterology', 110, 'Gastrointestinal Surgery'),
('D0012', 'Urology', 120, 'Kidney Stone Surgery');

--Payroll table: 
INSERT INTO Payroll (staff_id, account_number, account_type, salary) VALUES
('D007', '12345', 'Checking', EncryptByKey(Key_GUID(N'TestSymmetricKey'), CONVERT(varbinary,3000))),
('D006', '53758', 'Checking', EncryptByKey(Key_GUID(N'TestSymmetricKey'), CONVERT(varbinary,2500))),
('N53', '87368', 'Savings', EncryptByKey(Key_GUID(N'TestSymmetricKey'), CONVERT(varbinary,2000))),
('D001', '87368', 'Checking', EncryptByKey(Key_GUID(N'TestSymmetricKey'), CONVERT(varbinary,3200))),
('D009', '82736', 'Savings', EncryptByKey(Key_GUID(N'TestSymmetricKey'), CONVERT(varbinary,2700))),
('N61', '28368', 'Checking', EncryptByKey(Key_GUID(N'TestSymmetricKey'), CONVERT(varbinary,900))),
('D003', '28634', 'Savings', EncryptByKey(Key_GUID(N'TestSymmetricKey'), CONVERT(varbinary,3100))),
('D005', '28647', 'Checking', EncryptByKey(Key_GUID(N'TestSymmetricKey'), CONVERT(varbinary,2600))),
('N57', '27473', 'Savings', EncryptByKey(Key_GUID(N'TestSymmetricKey'), CONVERT(varbinary,2050))),
('N52', '78238', 'Checking', EncryptByKey(Key_GUID(N'TestSymmetricKey'), CONVERT(varbinary,1550))),
('D0011', '81364', 'Savings', EncryptByKey(Key_GUID(N'TestSymmetricKey'), CONVERT(varbinary,2650))),
('N54', '73683', 'Checking', EncryptByKey(Key_GUID(N'TestSymmetricKey'), CONVERT(varbinary,950)));

--Patient table
INSERT INTO Patient (patient_id, firstname, lastname, age, gender, date_of_birth, streetname, city, zipcode, country, phone, email, emergency_contact_name, emergency_contact, emergency_contact_relationship, pharmacy_id, insurance_id) VALUES
('PT001', 'Alex', 'Turner', 29, 'Male', '1994-06-17', '856 Juniper Dr', 'Atlanta', '30309', 'USA', '4045550123', 'alex.turner@example.com', 'Jamie Cook', '4045550145', 'Friend', 'P01', 'I21'),
('PT002', 'Emma', 'Stone', 34, 'Female', '1989-11-06', '42 Maple St', 'Chicago', '60614', 'USA', '3125550198', 'emma.stone@example.com', 'David Stone', '3125550178', 'Brother', 'P02', 'I22'),
('PT003', 'Liam', 'Nelson', 45, 'Male', '1978-03-22', '1287 Pine Tree Ln', 'Phoenix', '85021', 'USA', '6025550139', 'liam.nelson@example.com', 'Nora Nelson', '6025550162', 'Sister', 'P03', 'I23'),
('PT004', 'Sophia', 'Martinez', 52, 'Female', '1971-07-30', '975 Oak Ave', 'San Diego', '92103', 'USA', '6195550114', 'sophia.martinez@example.com', 'Carlos Martinez', '6195550156', 'Husband', 'P04', 'I24'),
('PT005', 'Ethan', 'Wright', 38, 'Male', '1985-05-18', '450 Elm St', 'Dallas', '75204', 'USA', '2145550127', 'ethan.wright@example.com', 'Mia Wright', '2145550189', 'Wife', 'P05', 'I25'),
('PT006', 'Isabella', 'Clark', 26, 'Female', '1997-02-15', '2345 Willow Way', 'Seattle', '98101', 'USA', '2065550140', 'isabella.clark@example.com', 'Evelyn Clark', '2065550102', 'Mother', 'P06', 'I26'),
('PT007', 'Mason', 'Rodriguez', 31, 'Male', '1992-08-12', '789 Maple St', 'Denver', '80203', 'USA', '3035550132', 'mason.rodriguez@example.com', 'Amelia Rodriguez', '3035550174', 'Sister', 'P07', 'I27'),
('PT008', 'Olivia', 'Brown', 28, 'Female', '1995-12-30', '1234 Pine St', 'Boston', '02108', 'USA', '6175550155', 'olivia.brown@example.com', 'Noah Brown', '6175550197', 'Brother', 'P08', 'I28'),
('PT009', 'Noah', 'Garcia', 40, 'Male', '1983-09-20', '876 Elm Dr', 'San Francisco', '94102', 'USA', '4155550129', 'noah.garcia@example.com', 'Grace Garcia', '4155550161', 'Wife', 'P09', 'I29'),
('PT010', 'Ava', 'Lopez', 30, 'Female', '1993-01-27', '6543 Cedar Ln', 'Los Angeles', '90012', 'USA', '3235550136', 'ava.lopez@example.com', 'Anthony Lopez', '3235550178', 'Husband', 'P010', 'I30'),
('PT011', 'William', 'Harris', 36, 'Male', '1987-05-14', '3212 Oak St', 'Houston', '77002', 'USA', '7135550143', 'william.harris@example.com', 'Elizabeth Harris', '7135550185', 'Sister', 'P011', 'I31'),
('PT012', 'Mia', 'Anderson', 33, 'Female', '1990-07-22', '987 Spruce St', 'Philadelphia', '19103', 'USA', '2155550199', 'mia.anderson@example.com', 'James Anderson', '2155550111', 'Father', 'P012', 'I32');


--Appointment table
INSERT INTO Appointment (appointment_id, "date", "time", patient_id, doctor_id, purpose) VALUES
('A0001', '2024-04-15', '09:00:00', 'PT001', 'D001', 'Routine Checkup'),
('A0002', '2024-04-16', '10:30:00', 'PT002', 'D002', 'Annual Physical Exam'),
('A0003', '2024-04-17', '11:00:00', 'PT003', 'D003', 'Consultation'),
('A0004', '2024-04-18', '14:00:00', 'PT004', 'D004', 'Follow-up'),
('A0005', '2024-04-19', '15:00:00', 'PT005', 'D005', 'Routine Checkup'),
('A0006', '2024-04-20', '09:30:00', 'PT006', 'D006', 'Vaccination'),
('A0007', '2024-04-21', '10:00:00', 'PT007', 'D007', 'Health Screening'),
('A0008', '2024-04-22', '08:45:00', 'PT008', 'D008', 'Consultation for Surgery'),
('A0009', '2024-04-23', '13:30:00', 'PT009', 'D009', 'Post-Operative Checkup'),
('A0010', '2024-04-24', '16:00:00', 'PT010', 'D010', 'Routine Checkup'),
('A0011', '2024-04-25', '14:15:00', 'PT011', 'D0011', 'Consultation'),
('A0012', '2024-04-26', '11:30:00', 'PT012', 'D0012', 'Emergency Consultation');

--Medical Record table
INSERT INTO Medical_Record (record_id, diagnosis, room_id, appointment_id) VALUES
('MR0001', 'Arrhythmia', 'Room10', 'A0001'), -- Cardiology
('MR0002', 'Osteoporosis', 'Room20', 'A0002'), -- Orthopedics
('MR0003', 'Epilepsy', 'Room30', 'A0003'), -- Neurology
('MR0004', 'Hypertension', 'Room40', 'A0004'), -- Cardiology
('MR0005', 'Arthritis', 'Room50', 'A0005'), -- Orthopedics
('MR0006', 'Asthma', 'Room60', 'A0006'), -- Pulmonology
('MR0007', 'Chickenpox', 'Room70', 'A0007'), -- Pediatrics
('MR0008', 'Eczema', 'Room80', 'A0008'), -- Dermatology
('MR0009', 'Glaucoma', 'Room90', 'A0009'), -- Ophthalmology
('MR0010', 'Leukemia', 'Room100', 'A0010'), -- Oncology
('MR0011', 'Gastritis', 'Room110', 'A0011'), -- Gastroenterology
('MR0012', 'Kidney Stones', 'Room120', 'A0012'); -- Urology

--Billing table
INSERT INTO Billing (billing_id, date_issued, amount, status, insurance_claim) VALUES
('B0001', '2024-04-16', 150, 'Paid', 'Yes'),
('B0002', '2024-04-17', 200, 'Unpaid', 'No'),
('B0003', '2024-04-18', 175, 'Paid', 'Yes'),
('B0004', '2024-04-19', 300, 'Unpaid', 'Yes'),
('B0005', '2024-04-20', 250, 'Paid', 'No'),
('B0006', '2024-04-21', 350, 'Paid', 'Yes'),
('B0007', '2024-04-22', 400, 'Unpaid', 'No'),
('B0008', '2024-04-23', 450, 'Paid', 'Yes'),
('B0009', '2024-04-24', 500, 'Unpaid', 'No'),
('B0010', '2024-04-25', 550, 'Paid', 'Yes'),
('B0011', '2024-04-26', 600, 'Unpaid', 'No'),
('B0012', '2024-04-27', 650, 'Paid', 'Yes');

--Treatment table

INSERT INTO Treatment (treatment_id, record_id, start_date, description, billing_id, test_id) VALUES
('TR0001', 'MR0001', '2024-04-17', 'Cardiac Treatment', 'B0001', 'LT123'),
('TR0002', 'MR0002', '2024-04-18', 'Osteoporosis Management', 'B0002', 'LT124'),
('TR0003', 'MR0003', '2024-04-19', 'Epilepsy Monitoring', 'B0003', 'LT125'),
('TR0004', 'MR0004', '2024-04-20', 'Hypertension Control', 'B0004', 'LT123'),
('TR0005', 'MR0005', '2024-04-21', 'Arthritis Treatment', 'B0005', 'LT124'),
('TR0006', 'MR0006', '2024-04-22', 'Asthma Management', 'B0006', 'LT126'),
('TR0007', 'MR0007', '2024-04-23', 'Chickenpox Care', 'B0007', 'LT127'),
('TR0008', 'MR0008', '2024-04-24', 'Eczema Treatment', 'B0008', 'LT128'),
('TR0009', 'MR0009', '2024-04-25', 'Glaucoma Monitoring', 'B0009', 'LT129'),
('TR0010', 'MR0010', '2024-04-26', 'Leukemia Treatment', 'B0010', 'LT130'),
('TR0011', 'MR0011', '2024-04-27', 'Gastritis Management', 'B0011', 'LT134'),
('TR0012', 'MR0012', '2024-04-28', 'Kidney Stones Treatment', 'B0012', 'LT132');

--Medication table
INSERT INTO Medication (medication_id, name, over_the_counter) VALUES
('MED001', 'Beta Blockers', 'No'), -- For Arrhythmia
('MED002', 'Bisphosphonates', 'No'), -- For Osteoporosis
('MED003', 'Levetiracetam', 'No'), -- For Epilepsy
('MED004', 'ACE Inhibitors', 'No'), -- For Hypertension
('MED005', 'NSAIDs', 'Yes'), -- For Arthritis
('MED006', 'Inhaled Corticosteroids', 'No'), -- For Asthma
('MED007', 'Acyclovir', 'No'), -- For Chickenpox
('MED008', 'Hydrocortisone', 'Yes'), -- For Eczema
('MED009', 'Timolol', 'No'), -- For Glaucoma
('MED010', 'Chemotherapy Drugs', 'No'), -- For Leukemia
('MED011', 'Proton Pump Inhibitors', 'No'), -- For Gastritis
('MED012', 'Alpha Blockers', 'No'); -- For Kidney Stones


--Prescription table
INSERT INTO Prescription (record_id, medication_id) VALUES
('MR0001', 'MED001'), -- Arrhythmia treated with Beta Blockers
('MR0002', 'MED002'), -- Osteoporosis treated with Bisphosphonates
('MR0003', 'MED003'), -- Epilepsy treated with Levetiracetam
('MR0004', 'MED004'), -- Hypertension treated with ACE Inhibitors
('MR0005', 'MED005'), -- Arthritis treated with NSAIDs
('MR0006', 'MED006'), -- Asthma treated with Inhaled Corticosteroids
('MR0007', 'MED007'), -- Chickenpox treated with Acyclovir
('MR0008', 'MED008'), -- Eczema treated with Hydrocortisone
('MR0009', 'MED009'), -- Glaucoma treated with Timolol
('MR0010', 'MED010'), -- Leukemia treated with Chemotherapy Drugs
('MR0011', 'MED011'), -- Gastritis treated with Proton Pump Inhibitors
('MR0012', 'MED012'); -- Kidney Stones treated with Alpha Blockers

--Queries

--Query for views

--View1 Query
SELECT * FROM HighRiskBills;

--View2 Query
Select * from StaffperDepartment 
ORDER BY Count_of_Doctors DESC, Count_of_Nurse DESC;

--View3 Query
SELECT * FROM PatientAppointments;

--View4 Query
SELECT * FROM DoctorSpecialties
ORDER BY patient_count DESC;

--Encryption
--Query before decrypting
SELECT * FROM Payroll
--Query after decrypting
SELECT staff_id, account_number, account_type, CONVERT(INT, DecryptByKey(salary)) AS Salary
FROM Payroll

--Computed Columns based on a function
SELECT * FROM Billing;
