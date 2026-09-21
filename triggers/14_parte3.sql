-- DDL para tablas de auditoría requeridas (audit_tenants ya existe en DDL original)
CREATE TABLE IF NOT EXISTS audit_templates (
    id SERIAL PRIMARY KEY,
    template_id INT NOT NULL,
    field_changed VARCHAR(80),
    old_value TEXT,
    new_value TEXT,
    changed_by VARCHAR(80),
    changed_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 11. Valida que el porcentaje de cumplimiento calculado permanezca dentro del rango de 0 a 100 (sobre evaluations).
CREATE OR REPLACE FUNCTION trg_fn_validate_evaluation_score()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- La constraint ck_evaluations_score ya hace esto, pero lo interceptamos aquí para dar un mensaje amigable
    IF NEW.score < 0 OR NEW.score > 100 THEN
        RAISE EXCEPTION 'El porcentaje de cumplimiento (%) debe estar entre 0 y 100, valor recibido: %', NEW.score;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_validate_evaluation_score
BEFORE INSERT OR UPDATE ON evaluations
FOR EACH ROW
EXECUTE FUNCTION trg_fn_validate_evaluation_score();


-- 12. Registra en una tabla de auditoría cualquier modificación (AFTER UPDATE) realizada sobre los datos principales de una organización.
CREATE OR REPLACE FUNCTION trg_fn_audit_tenant_update()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Se registra de manera general que hubo un UPDATE sobre la fila
    INSERT INTO audit_tenants (tenant_id, field_changed, changed_by, changed_at)
    VALUES (NEW.id, 'ACTUALIZACION_GENERAL', current_user, NOW());
    
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_audit_tenant_update
AFTER UPDATE ON tenants
FOR EACH ROW
EXECUTE FUNCTION trg_fn_audit_tenant_update();


-- 13. Almacena el valor anterior y el nuevo valor cuando se modifique el estado de una organización en tenants.
CREATE OR REPLACE FUNCTION trg_fn_audit_tenant_is_active()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Solo audita si hubo un cambio real en el campo is_active
    IF OLD.is_active IS DISTINCT FROM NEW.is_active THEN
        INSERT INTO audit_tenants (tenant_id, field_changed, old_value, new_value, changed_by, changed_at)
        VALUES (NEW.id, 'is_active', OLD.is_active::TEXT, NEW.is_active::TEXT, current_user, NOW());
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_audit_tenant_is_active
AFTER UPDATE ON tenants
FOR EACH ROW
EXECUTE FUNCTION trg_fn_audit_tenant_is_active();


-- 14. Registra la fecha y el usuario responsable en una tabla de auditoría cuando una plantilla sea modificada.
CREATE OR REPLACE FUNCTION trg_fn_audit_template_update()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO audit_templates (template_id, field_changed, changed_by, changed_at)
    VALUES (NEW.id, 'MODIFICACION_PLANTILLA', current_user, NOW());
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_audit_template_update
AFTER UPDATE ON templates
FOR EACH ROW
EXECUTE FUNCTION trg_fn_audit_template_update();


-- 15. Elimina físicamente los bloqueos de edición que ya estén vencidos antes de insertar uno nuevo en editing_locks.
CREATE OR REPLACE FUNCTION trg_fn_cleanup_expired_editing_locks()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Elimina bloqueos vencidos para este mismo recurso
    DELETE FROM editing_locks 
    WHERE expires_at < NOW() 
      AND resource_type = NEW.resource_type 
      AND resource_id = NEW.resource_id;
      
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_cleanup_expired_editing_locks
BEFORE INSERT ON editing_locks
FOR EACH ROW
EXECUTE FUNCTION trg_fn_cleanup_expired_editing_locks();
