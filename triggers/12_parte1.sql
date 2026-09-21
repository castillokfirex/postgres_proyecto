-- 1. Actualiza automáticamente updated_at cada vez que se modifique un registro de tenants.
CREATE OR REPLACE FUNCTION trg_fn_update_tenants_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_update_tenants_updated_at
BEFORE UPDATE ON tenants
FOR EACH ROW
EXECUTE FUNCTION trg_fn_update_tenants_updated_at();

-- 2. Actualiza automáticamente updated_at cuando se modifique un registro de persons.
CREATE OR REPLACE FUNCTION trg_fn_update_persons_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_update_persons_updated_at
BEFORE UPDATE ON persons
FOR EACH ROW
EXECUTE FUNCTION trg_fn_update_persons_updated_at();

-- 3. Impide registrar una persona (INSERT en persons) en una organización que se encuentre inactiva.
CREATE OR REPLACE FUNCTION trg_fn_check_tenant_active_for_person()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_is_active BOOLEAN;
    v_tenant_id INT;
BEGIN
    SELECT t.id, t.is_active INTO v_tenant_id, v_is_active 
    FROM positions pos
    INNER JOIN tenants t ON pos.tenant_id = t.id
    WHERE pos.id = NEW.position_id;
    
    IF v_is_active IS FALSE THEN
        RAISE EXCEPTION 'No se puede registrar la persona porque la organización con ID % se encuentra inactiva.', v_tenant_id;
    END IF;
    
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_check_tenant_active_for_person
BEFORE INSERT ON persons
FOR EACH ROW
EXECUTE FUNCTION trg_fn_check_tenant_active_for_person();

-- 4. Impide asignar un módulo a una organización cuando dicho módulo ya se encuentre previamente asignado.
CREATE OR REPLACE FUNCTION trg_fn_check_duplicate_tenant_module()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM tenant_modules WHERE tenant_id = NEW.tenant_id AND module_id = NEW.module_id) THEN
        RAISE EXCEPTION 'El módulo con ID % ya se encuentra asignado a la organización con ID %.', NEW.module_id, NEW.tenant_id;
    END IF;
    
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_check_duplicate_tenant_module
BEFORE INSERT ON tenant_modules
FOR EACH ROW
EXECUTE FUNCTION trg_fn_check_duplicate_tenant_module();

-- 5. Impide asignar plantillas (INSERT en tenant_templates) a organizaciones cuyo estado se encuentre inactivo.
CREATE OR REPLACE FUNCTION trg_fn_check_tenant_active_for_template()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_is_active BOOLEAN;
BEGIN
    SELECT is_active INTO v_is_active FROM tenants WHERE id = NEW.tenant_id;
    
    IF v_is_active IS FALSE THEN
        RAISE EXCEPTION 'No se pueden asignar plantillas a la organización con ID % porque se encuentra inactiva.', NEW.tenant_id;
    END IF;
    
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_check_tenant_active_for_template
BEFORE INSERT ON tenant_templates
FOR EACH ROW
EXECUTE FUNCTION trg_fn_check_tenant_active_for_template();

-- 6. Impide insertar o actualizar un email si ya existe en la misma organización.
CREATE OR REPLACE FUNCTION trg_fn_check_unique_email_per_tenant()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_tenant_id INT;
BEGIN
    SELECT t.id INTO v_tenant_id 
    FROM positions pos
    INNER JOIN tenants t ON pos.tenant_id = t.id
    WHERE pos.id = NEW.position_id;
    
    IF EXISTS (
        SELECT 1 
        FROM persons p
        INNER JOIN positions pos ON p.position_id = pos.id
        WHERE pos.tenant_id = v_tenant_id AND p.email = NEW.email 
          AND (TG_OP = 'INSERT' OR p.id != NEW.id)
    ) THEN
        RAISE EXCEPTION 'El correo % ya está registrado para la organización %.', NEW.email, v_tenant_id;
    END IF;
    
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_check_unique_email_per_tenant
BEFORE INSERT OR UPDATE OF email, position_id ON persons
FOR EACH ROW
EXECUTE FUNCTION trg_fn_check_unique_email_per_tenant();
