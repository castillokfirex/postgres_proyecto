-- NOTA: El Trigger 6 fue eliminado porque en 3FN/4FN la tabla 'persons' ya no tiene 'tenant_id'. 
-- El tenant se infiere directamente desde 'position_id', haciendo imposible la discrepancia.


-- 7. Registra automáticamente la fecha de actualización (updated_at) cuando se produzca una modificación en una plantilla asignada.
CREATE OR REPLACE FUNCTION trg_fn_update_tenant_templates_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_update_tenant_templates_updated_at
BEFORE UPDATE ON tenant_templates
FOR EACH ROW
EXECUTE FUNCTION trg_fn_update_tenant_templates_updated_at();


-- 8. Impide eliminar una organización (BEFORE DELETE en tenants) cuando todavía existan personas asociadas a ella.
CREATE OR REPLACE FUNCTION trg_fn_prevent_tenant_delete_if_persons()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM persons p
        INNER JOIN positions pos ON p.position_id = pos.id
        WHERE pos.tenant_id = OLD.id
    ) THEN
        RAISE EXCEPTION 'No se puede eliminar la organización (ID %) porque tiene personas asociadas en la tabla persons.', OLD.id;
    END IF;
    RETURN OLD;
END;
$$;

CREATE TRIGGER trg_prevent_tenant_delete_if_persons
BEFORE DELETE ON tenants
FOR EACH ROW
EXECUTE FUNCTION trg_fn_prevent_tenant_delete_if_persons();


-- 9. Impide eliminar un sistema SST (BEFORE DELETE en type_system_sst) cuando existan organizaciones que lo estén utilizando.
CREATE OR REPLACE FUNCTION trg_fn_prevent_type_system_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM tenantsystems WHERE type_system_sst_id = OLD.id) THEN
        RAISE EXCEPTION 'No se puede eliminar el sistema SST (ID %) porque está siendo utilizado por una o más organizaciones.', OLD.id;
    END IF;
    RETURN OLD;
END;
$$;

CREATE TRIGGER trg_prevent_type_system_delete
BEFORE DELETE ON type_system_sst
FOR EACH ROW
EXECUTE FUNCTION trg_fn_prevent_type_system_delete();


-- 10. Impide eliminar un módulo (BEFORE DELETE en modules) cuando dicho módulo esté asignado a una o más organizaciones.
CREATE OR REPLACE FUNCTION trg_fn_prevent_module_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM tenant_modules WHERE module_id = OLD.id) THEN
        RAISE EXCEPTION 'No se puede eliminar el módulo (ID %) porque está asignado a una o más organizaciones en tenant_modules.', OLD.id;
    END IF;
    RETURN OLD;
END;
$$;

CREATE TRIGGER trg_prevent_module_delete
BEFORE DELETE ON modules
FOR EACH ROW
EXECUTE FUNCTION trg_fn_prevent_module_delete();
