-- Лабораторна робота №3
-- З дисципліни: Бази даних та інформаційні системи
-- Студентки групи МІТ-31 Пась Олександри

--1.Логічні оператори

--1.1 Поліси з вартістю більше 5000 та тривалістю більше 256 днів
SELECT * 
FROM policies
WHERE premium > 5000 
AND (end_date - start_date) > 256;

--1.2 Клієнти з Києва або Львова
SELECT *
FROM clients
WHERE address LIKE '%Київ%' OR address LIKE '%Львів%';

--1.3 Страхові випадки, які не були відхилені
SELECT *
FROM claims
WHERE status != 'rejected';

--2.Агрегатні функції

--2.1 Кількість полісів кожного типу
SELECT it.name, COUNT(p.id) AS total_policies
FROM insurance_types it
LEFT JOIN policies p ON it.id = p.insurance_type_id
GROUP BY it.name;

--2.2 Середня вартість полісів
SELECT AVG(premium) AS average_premium 
FROM policies;

--2.3 Мінімальна та максимальна сума виплат
SELECT MIN(amount) AS min_payout, MAX(amount) AS max_payout
FROM payouts;

--2.4 Загальна сума виплат за кожний тип страхування
SELECT it.name, SUM(po.amount) AS total_payouts
FROM insurance_types it
JOIN policies p ON it.id = p.insurance_type_id
JOIN claims cl ON p.id = cl.policy_id
JOIN payouts po ON cl.id = po.claim_id
GROUP BY it.name;

--3. Різні типи JOIN

--3.1 INNER JOIN - Поліси з інформацією про клієнтів
SELECT p.*, c.full_name 
FROM policies p
INNER JOIN clients c ON p.client_id = c.id;

--3.2 LEFT JOIN - Всі клієнти та їхні поліси
SELECT c.full_name, p.policy_number 
FROM clients c
LEFT JOIN policies p ON c.id = p.client_id;

--3.3 RIGHT JOIN - Всі виплати, навіть без пов'язаних випадків
SELECT po.*, cl.description 
FROM claims cl
RIGHT JOIN payouts po ON cl.id = po.claim_id;

--3.4 FULL JOIN - Всі клієнти та всі поліси
SELECT c.full_name, p.policy_number 
FROM clients c
FULL JOIN policies p ON c.id = p.client_id;

--3.5 CROSS JOIN - Комбінації клієнтів і типів страхування
SELECT c.full_name, it.name 
FROM clients c
CROSS JOIN insurance_types it
LIMIT 100;

--3.6 SELF JOIN - Клієнти з однаковими прізвищами
SELECT a.full_name, b.full_name 
FROM clients a
JOIN clients b ON a.full_name = b.full_name AND a.id != b.id;

--4. Підзапити

--4.1 Клієнти без полісів
SELECT * 
FROM clients 
WHERE id NOT IN (SELECT client_id FROM policies);

--4.2 Поліси з виплатами вище середнього
SELECT * 
FROM policies
WHERE id IN (
    SELECT policy_id 
    FROM claims 
    WHERE id IN (
        SELECT claim_id 
        FROM payouts 
        WHERE amount > (SELECT AVG(amount) FROM payouts)
    )
);

--4.3 Клієнти, які мають хоча б один поліс
SELECT * 
FROM clients c
WHERE EXISTS (
    SELECT 1 
    FROM policies p 
    WHERE p.client_id = c.id
);

--4.4 Типи страхування без полісів
SELECT * 
FROM insurance_types it
WHERE NOT EXISTS (
    SELECT 1 
    FROM policies p 
    WHERE p.insurance_type_id = it.id
);

--5. Операції над множинами

--5.1 UNION - Клієнти з Києва та з полісами вартістю > 5000
SELECT id, full_name FROM clients WHERE address LIKE '%Київ%'
UNION
SELECT c.id, c.full_name 
FROM clients c
JOIN policies p ON c.id = p.client_id
WHERE p.premium > 5000;

--5.2 INTERSECT - Клієнти з Києва, які мають поліси
SELECT id, full_name FROM clients WHERE address LIKE '%Київ%'
INTERSECT
SELECT c.id, c.full_name 
FROM clients c
JOIN policies p ON c.id = p.client_id;

--5.3 EXCEPT - Клієнти без полісів
SELECT id, full_name FROM clients
EXCEPT
SELECT c.id, c.full_name 
FROM clients c
JOIN policies p ON c.id = p.client_id;

--6. CTE (Common Table Expressions)

--6.1 Середня вартість полісів за місяцями
WITH monthly_stats AS (
    SELECT 
        EXTRACT(MONTH FROM start_date) AS month,
        AVG(premium) AS avg_premium
    FROM policies
    GROUP BY month
)
SELECT * FROM monthly_stats
ORDER BY month;

--6.2 Клієнти з кількістю полісів
WITH client_policies AS (
    SELECT 
        client_id, 
        COUNT(*) AS policy_count
    FROM policies
    GROUP BY client_id
)
SELECT 
    c.full_name, 
    cp.policy_count
FROM 
    clients c
JOIN client_policies cp ON c.id = cp.client_id
ORDER BY cp.policy_count DESC;

--6.3 Віконна функція - Рейтинг клієнтів за сумою виплат
SELECT 
    c.id,
    c.full_name,
    SUM(po.amount) AS total_payouts,
    RANK() OVER (ORDER BY SUM(po.amount) DESC) AS rank
FROM 
    clients c
JOIN 
    policies p ON c.id = p.client_id
JOIN 
    claims cl ON p.id = cl.policy_id
JOIN 
    payouts po ON cl.id = po.claim_id
GROUP BY 
    c.id, c.full_name;

--7. Додаткові аналітичні запити

--7.1 Поліси з найбільшою кількістю виплат
SELECT 
    p.policy_number,
    COUNT(cl.id) AS claims_count,
    SUM(po.amount) AS total_payouts
FROM 
    policies p
LEFT JOIN 
    claims cl ON p.id = cl.policy_id
LEFT JOIN 
    payouts po ON cl.id = po.claim_id
GROUP BY 
    p.id
ORDER BY 
    claims_count DESC;

--7.2 Аналіз виплат за типами страхування
SELECT 
    it.name AS insurance_type,
    COUNT(po.id) AS payout_count,
    SUM(po.amount) AS total_payouts,
    AVG(po.amount) AS average_payout
FROM 
    insurance_types it
LEFT JOIN 
    policies p ON it.id = p.insurance_type_id
LEFT JOIN 
    claims cl ON p.id = cl.policy_id
LEFT JOIN 
    payouts po ON cl.id = po.claim_id
GROUP BY 
    it.name
ORDER BY 
    total_payouts DESC;

--7.3 Клієнти з найвищими виплатами
SELECT 
    c.full_name,
    COUNT(po.id) AS payout_count,
    SUM(po.amount) AS total_payouts
FROM 
    clients c
JOIN 
    policies p ON c.id = p.client_id
JOIN 
    claims cl ON p.id = cl.policy_id
JOIN 
    payouts po ON cl.id = po.claim_id
GROUP BY 
    c.id
ORDER BY 
    total_payouts DESC
LIMIT 10;

--7.4 Аналіз статусів страхових випадків
SELECT 
    status,
    COUNT(*) AS claim_count,
    AVG(estimated_loss) AS avg_loss,
    SUM(estimated_loss) AS total_loss
FROM 
    claims
GROUP BY 
    status;

--7.5 Поліси, що закінчуються в наступному місяці
SELECT 
    p.policy_number,
    c.full_name,
    p.end_date
FROM 
    policies p
JOIN 
    clients c ON p.client_id = c.id
WHERE 
    EXTRACT(MONTH FROM p.end_date) = EXTRACT(MONTH FROM CURRENT_DATE + INTERVAL '1 month')
    AND EXTRACT(YEAR FROM p.end_date) = EXTRACT(YEAR FROM CURRENT_DATE);

--29.Кількість активних та неактивних полісів
SELECT 
    status,
    COUNT(*) AS policy_count
FROM policies
GROUP BY status;

--30. Топ-4 найдорожчих полісів
SELECT 
    policy_number,
    insured_amount,
    premium
FROM policies
ORDER BY premium DESC
LIMIT 4;

--31. Клієнти з найбільшою кількістю страхових випадків
SELECT 
    c.full_name,
    COUNT(cl.id) AS claims_count
FROM clients c
JOIN policies p ON c.id = p.client_id
JOIN claims cl ON p.id = cl.policy_id
GROUP BY c.id
ORDER BY claims_count DESC
LIMIT 2;

--32. Середній час розгляду страхових випадків
SELECT 
    AVG(decision_date - claim_date) AS avg_processing_days
FROM claims
WHERE decision_date IS NOT NULL;

--33. Розподіл виплат за методами оплати
SELECT 
    method,
    COUNT(*) AS payout_count,
    SUM(amount) AS total_amount
FROM payouts
GROUP BY method;

--34. Поліси з простроченими виплатами
SELECT 
    p.policy_number,
    c.full_name,
    po.amount,
    po.payout_date
FROM payouts po
JOIN claims cl ON po.claim_id = cl.id
JOIN policies p ON cl.policy_id = p.id
JOIN clients c ON p.client_id = c.id
WHERE po.status = 'pending' AND po.payout_date < CURRENT_DATE;

--35. Клієнти з кількома типами страхування
SELECT 
    c.full_name,
    COUNT(DISTINCT p.insurance_type_id) AS insurance_types_count
FROM clients c
JOIN policies p ON c.id = p.client_id
GROUP BY c.id
HAVING COUNT(DISTINCT p.insurance_type_id) > 1;

--36. Страхові випадки за місяцями
SELECT 
    EXTRACT(MONTH FROM claim_date) AS month,
    EXTRACT(YEAR FROM claim_date) AS year,
    COUNT(*) AS claims_count
FROM claims
GROUP BY year, month
ORDER BY year, month;

--37. Співвідношення оцінки збитків до фактичних виплат
SELECT 
    cl.id AS claim_id,
    cl.estimated_loss,
    po.amount AS actual_payout,
    (po.amount / cl.estimated_loss * 100) AS percentage_paid
FROM claims cl
JOIN payouts po ON cl.id = po.claim_id
WHERE cl.estimated_loss > 0;

--38. Найчастіші причини страхових випадків
SELECT 
    SUBSTRING(description FROM 1 FOR 30) AS reason_excerpt,
    COUNT(*) AS frequency
FROM claims
GROUP BY reason_excerpt
ORDER BY frequency DESC
LIMIT 10;

--39. Поліси з найвищим співвідношенням виплат до премії
SELECT 
    p.policy_number,
    p.premium,
    SUM(po.amount) AS total_payouts,
    (SUM(po.amount) / p.premium * 100) AS payout_ratio
FROM policies p
JOIN claims cl ON p.id = cl.policy_id
JOIN payouts po ON cl.id = po.claim_id
GROUP BY p.id
HAVING SUM(po.amount) > 0
ORDER BY payout_ratio DESC
LIMIT 5;

-- 40.Аналіз клієнтів за кількістю полісів, виплатами та середнім часом розгляду випадків
SELECT 
    c.id AS client_id,
    c.full_name,
    COUNT(DISTINCT p.id) AS total_policies,
    COUNT(DISTINCT cl.id) AS total_claims,
    COALESCE(SUM(po.amount), 0) AS total_payouts,
    CASE 
        WHEN COUNT(cl.id) > 0 THEN AVG(cl.decision_date - cl.claim_date)
        ELSE NULL 
    END AS avg_processing_days,
    CASE 
        WHEN COUNT(p.id) > 0 THEN COUNT(cl.id)::float / COUNT(p.id)
        ELSE 0 
    END AS claims_per_policy_ratio
FROM 
    clients c
LEFT JOIN 
    policies p ON c.id = p.client_id
LEFT JOIN 
    claims cl ON p.id = cl.policy_id
LEFT JOIN 
    payouts po ON cl.id = po.claim_id
GROUP BY 
    c.id
ORDER BY 
    total_payouts DESC;