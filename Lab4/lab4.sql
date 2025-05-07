-- 1. Спочатку створюємо новий тип ENUM
CREATE TYPE payouts_status_type AS ENUM ('pending', 'completed', 'failed');

-- 2. Видаляємо обмеження DEFAULT зі стовпця status
ALTER TABLE payouts ALTER COLUMN status DROP DEFAULT;

-- 3. Змінюємо тип стовпця з явним перетворенням значень
ALTER TABLE payouts 
ALTER COLUMN status TYPE payouts_status_type 
USING (
    CASE status
        WHEN 'pending' THEN 'pending'::payouts_status_type
        WHEN 'completed' THEN 'completed'::payouts_status_type
        WHEN 'failed' THEN 'failed'::payouts_status_type
        ELSE 'pending'::payouts_status_type  -- значення за замовчуванням для інших випадків
    END
);

-- 4. Встановлюємо нове значення за замовчуванням
ALTER TABLE payouts 
ALTER COLUMN status SET DEFAULT 'pending'::payouts_status_type;

SELECT * FROM payouts;


--Створення користувацької функції
CREATE OR REPLACE FUNCTION client_payouts_analysis(client_id_param INT) 
RETURNS TABLE (
    total_amount DECIMAL(12,2), 
    completed_amount DECIMAL(12,2), 
    pending_amount DECIMAL(12,2),
    failed_amount DECIMAL(12,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(SUM(po.amount), 0) AS total_amount,
        COALESCE(SUM(CASE WHEN po.status = 'completed' THEN po.amount ELSE 0 END), 0) AS completed_amount,
        COALESCE(SUM(CASE WHEN po.status = 'pending' THEN po.amount ELSE 0 END), 0) AS pending_amount,
        COALESCE(SUM(CASE WHEN po.status = 'failed' THEN po.amount ELSE 0 END), 0) AS failed_amount
    FROM payouts po
    JOIN claims cl ON po.claim_id = cl.id
    JOIN policies p ON cl.policy_id = p.id
    WHERE p.client_id = client_id_param;
END;
$$ LANGUAGE plpgsql;

-- Приклад використання функції
SELECT * FROM client_payouts_analysis(1);

-- Таблиця для логування змін у виплатах
CREATE TABLE payouts_log (
    log_id SERIAL PRIMARY KEY,
    payout_id INT NOT NULL,
    operation VARCHAR(10) NOT NULL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_name TEXT DEFAULT CURRENT_USER,
    old_status payouts_status_type,
    new_status payouts_status_type,
    old_amount DECIMAL(12,2),
    new_amount DECIMAL(12,2)
);

-- Тригерна функція для логування змін
CREATE OR REPLACE FUNCTION log_payout_changes() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO payouts_log (payout_id, operation, new_status, new_amount)
        VALUES (NEW.id, TG_OP, NEW.status, NEW.amount);
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO payouts_log (payout_id, operation, old_status, new_status, old_amount, new_amount)
        VALUES (NEW.id, TG_OP, OLD.status, NEW.status, OLD.amount, NEW.amount);
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO payouts_log (payout_id, operation, old_status, old_amount)
        VALUES (OLD.id, TG_OP, OLD.status, OLD.amount);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Додавання тригера до таблиці payouts
CREATE TRIGGER track_payout_changes
AFTER INSERT OR UPDATE OR DELETE ON payouts
FOR EACH ROW
EXECUTE FUNCTION log_payout_changes();

-- Тестування ENUM типу
INSERT INTO payouts (claim_id, amount, payout_date, method, status)
VALUES (1, 5000.00, '2023-12-01', 'bank_transfer', 'pending');

-- Оновлення статусу виплати
UPDATE payouts SET status = 'failed' WHERE id = 1;
SELECT * FROM payouts;
-- Видалення виплати
DELETE FROM payouts WHERE id = 1;

SELECT * FROM payouts_log;
