-- Таблиця клієнтів
CREATE TABLE clients (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    birth_date DATE,
    passport_number VARCHAR(20) UNIQUE NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(50),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- Типи страхування
CREATE TABLE insurance_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    base_rate DECIMAL(5,2) NOT NULL
);
-- Страхові поліси
CREATE TABLE policies (
    id SERIAL PRIMARY KEY,
    client_id INTEGER REFERENCES clients(id) ON DELETE CASCADE,
    insurance_type_id INTEGER REFERENCES insurance_types(id),
    policy_number VARCHAR(20) UNIQUE NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    insured_amount DECIMAL(12,2) NOT NULL,
    premium DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    CHECK (end_date > start_date)
);
-- Страхові випадки
CREATE TABLE claims (
    id SERIAL PRIMARY KEY,
    policy_id INTEGER REFERENCES policies(id),
    claim_date DATE NOT NULL,
    description TEXT NOT NULL,
    estimated_loss DECIMAL(12,2),
    status VARCHAR(20) DEFAULT 'pending',
    decision_date DATE
);
-- Виплати
CREATE TABLE payouts (
    id SERIAL PRIMARY KEY,
    claim_id INTEGER REFERENCES claims(id),
    amount DECIMAL(12,2) NOT NULL,
    payout_date DATE NOT NULL,
    method VARCHAR(20) NOT NULL,
    status VARCHAR(20) DEFAULT 'completed'
);


-- Додавання типів страхування
INSERT INTO insurance_types (name, description, base_rate) VALUES
('Авто-КАСКО', 'Страхування транспортних засобів від пошкоджень та крадіжок', 3.5),
('ОСАГО', 'Обовязкове страхування цивільної відповідальності', 1.2),
('Медичне', 'Страхування медичних витрат', 2.8),
('Майно', 'Страхування нерухомості та домашнього майна', 1.5),
('Життя', 'Страхування життя та від нещасних випадків', 4.0);

-- Додавання клієнтів
INSERT INTO clients (full_name, birth_date, passport_number, phone, email, address) VALUES
('Іванов Петро Сидорович', '1985-05-15', 'КМ123456', '+380501234567', 'ivanov@example.com', 'м. Київ, вул. Хрещатик, 1'),
('Петрова Марія Іванівна', '1990-08-22', 'КМ654321', '+380671234567', 'petrova@example.com', 'м. Львів, вул. Свободи, 10'),
('Сидоренко Олексій Володимирович', '1978-03-10', 'КМ987654', '+380631234567', 'sydorenko@example.com', 'м. Одеса, вул. Дерибасівська, 5');

-- Додавання полісів
INSERT INTO policies (client_id, insurance_type_id, policy_number, start_date, end_date, insured_amount, premium) VALUES
(1, 1, 'AUTO-2023-001', '2023-01-15', '2024-01-14', 250000.00, 8750.00),
(1, 3, 'MED-2023-001', '2023-02-01', '2024-01-31', 100000.00, 2800.00),
(2, 2, 'OSAGO-2023-001', '2023-01-10', '2024-01-09', 50000.00, 600.00),
(3, 4, 'PROP-2023-001', '2023-03-01', '2024-02-28', 500000.00, 7500.00);

-- Додавання страхових випадків
INSERT INTO claims (policy_id, claim_date, description, estimated_loss, status, decision_date) VALUES
(1, '2023-05-20', 'ДТП, пошкодження переднього бампера', 15000.00, 'approved', '2023-05-25'),
(3, '2023-06-15', 'Пошкодження автомобіля третьої сторони', 8000.00, 'approved', '2023-06-20'),
(1, '2023-07-10', 'Крадіжка автомобіля', 250000.00, 'pending', NULL);

-- Додавання виплат
INSERT INTO payouts (claim_id, amount, payout_date, method, status) VALUES
(1, 15000.00, '2023-05-28', 'bank_transfer', 'completed'),
(2, 8000.00, '2023-06-22', 'bank_transfer', 'completed');

-- 1. Вибірка всіх клієнтів
SELECT * FROM clients;
-- 2. Сортування полісів за сумою страхування
SELECT policy_number, insured_amount, premium 
FROM policies
ORDER BY insured_amount DESC;
-- 3. Групування полісів за типом страхування
SELECT it.name, COUNT(p.id) as policy_count, SUM(p.insured_amount) as total_insured
FROM policies p
JOIN insurance_types it ON p.insurance_type_id = it.id
GROUP BY it.name
HAVING COUNT(p.id) > 0;
-- 4. Об'єднання таблиць для аналізу виплат
SELECT c.full_name, p.policy_number, cl.claim_date, cl.estimated_loss, po.amount, po.payout_date
FROM payouts po
JOIN claims cl ON po.claim_id = cl.id
JOIN policies p ON cl.policy_id = p.id
JOIN clients c ON p.client_id = c.id;
-- 5. Агрегатні функції для аналізу виплат
SELECT 
    COUNT(*) as total_claims,
    SUM(estimated_loss) as total_estimated_loss,
    AVG(estimated_loss) as average_claim,
    MAX(estimated_loss) as max_claim
FROM claims
WHERE status = 'approved';
-- 6. Пошук клієнтів з найбільшою кількістю полісів
SELECT c.full_name, COUNT(p.id) as policy_count
FROM clients c
LEFT JOIN policies p ON c.id = p.client_id
GROUP BY c.id
ORDER BY policy_count DESC;
-- 7. Аналіз виплат за місяцями
SELECT 
    EXTRACT(MONTH FROM payout_date) as month,
    EXTRACT(YEAR FROM payout_date) as year,
    COUNT(*) as payout_count,
    SUM(amount) as total_payouts
FROM payouts
GROUP BY year, month
ORDER BY year, month;

-- Відповіді на питання 
--Які типи страхових полісів пропонує компанія?
SELECT name, description 
FROM insurance_types;

--Скільки клієнтів придбали поліси в цьому місяці?
SELECT COUNT(DISTINCT client_id) AS new_clients_this_month
FROM policies
WHERE EXTRACT(MONTH FROM start_date) = EXTRACT(MONTH FROM CURRENT_DATE)
AND EXTRACT(YEAR FROM start_date) = EXTRACT(YEAR FROM CURRENT_DATE);

--Яка загальна сума виплат по полісах за певний період?
SELECT SUM(amount) AS total_payouts
FROM payouts
WHERE payout_date BETWEEN '2023-01-01' AND '2023-12-31';

--Яка середня вартість страхового поліса?
SELECT AVG(premium) AS average_premium
FROM policies;

--Скільки клієнтів мають кілька полісів одночасно?
SELECT COUNT(*) AS clients_with_multiple_policies
FROM (
    SELECT client_id
    FROM policies
    GROUP BY client_id
    HAVING COUNT(*) > 1
) AS multiple_policy_clients;
-- Які клієнти зробили найбільше заяв на виплати?
SELECT 
    c.id AS client_id, 
    c.full_name, 
    COUNT(p.id) AS policy_count
FROM 
    clients c
JOIN 
    policies p ON c.id = p.client_id
GROUP BY 
    c.id, c.full_name
HAVING 
    COUNT(p.id) > 1
ORDER BY 
    policy_count DESC;

--Які клієнти мають найбільші суми страхових виплат?
SELECT 
    c.id AS client_id,
    c.full_name,
    COUNT(cl.id) AS claims_count,
    SUM(po.amount) AS total_payouts,
    ROUND(AVG(po.amount), 2) AS average_payout
FROM 
    clients c
JOIN 
    policies p ON c.id = p.client_id
JOIN 
    claims cl ON p.id = cl.policy_id
JOIN 
    payouts po ON cl.id = po.claim_id
GROUP BY 
    c.id, c.full_name
ORDER BY 
    total_payouts DESC
LIMIT 10;

