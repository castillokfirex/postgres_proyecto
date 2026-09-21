# Triggers — Proyecto SST/PESV

Este documento contiene **únicamente los triggers** solicitados en la sección **"7. Triggers"** de `Examen.md`, implementados sobre el esquema definido en `base_datos_sst_pesv.md`. No se crean tablas, columnas ni objetos adicionales a los ya existentes en dicho script DDL.

Cada trigger se presenta con:
1. El enunciado tal como aparece en `Examen.md`.
2. La función `PL/pgSQL` asociada (`FUNCTION ... RETURNS TRIGGER`).
3. La sentencia `CREATE TRIGGER` correspondiente.

---

## Trigger 1
**Enunciado:** El estudiante deberá implementar un trigger que actualice automáticamente el campo `updated_at` cada vez que se modifique un registro de la tabla `tenants`.

```sql
CREATE OR REPLACE FUNCTION fn_tenants_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tenants_set_updated_at
BEFORE UPDATE ON tenants
FOR EACH ROW
EXECUTE FUNCTION fn_tenants_set_updated_at();
```

---

## Trigger 2
**Enunciado:** El estudiante deberá implementar un trigger que actualice automáticamente el campo `updated_at` cuando se modifique información de una persona.

```sql
CREATE OR REPLACE FUNCTION fn_persons_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_persons_set_updated_at
BEFORE UPDATE ON persons
FOR EACH ROW
EXECUTE FUNCTION fn_persons_set_updated_at();
```

---

## Trigger 3
**Enunciado:** El estudiante deberá implementar un trigger que impida registrar una persona en una organización que se encuentre inactiva.

```sql
CREATE OR REPLACE FUNCTION fn_persons_check_tenant_active()
RETURNS TRIGGER AS $$
DECLARE
    v_status VARCHAR(20);
BEGIN
    SELECT status INTO v_status
    FROM tenants
    WHERE tenant_id = NEW.tenant_id;

    IF v_status = 'inactivo' THEN
        RAISE EXCEPTION 'No se puede registrar una persona: la organización % se encuentra inactiva', NEW.tenant_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_persons_check_tenant_active
BEFORE INSERT ON persons
FOR EACH ROW
EXECUTE FUNCTION fn_persons_check_tenant_active();
```

---

## Trigger 4
**Enunciado:** El estudiante deberá implementar un trigger que impida asignar un módulo a una organización cuando dicho módulo ya se encuentre previamente asignado.

```sql
CREATE OR REPLACE FUNCTION fn_tenant_modules_prevent_duplicate()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM tenant_modules
        WHERE tenant_id = NEW.tenant_id
          AND module_id = NEW.module_id
    ) THEN
        RAISE EXCEPTION 'El módulo % ya se encuentra asignado a la organización %', NEW.module_id, NEW.tenant_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tenant_modules_prevent_duplicate
BEFORE INSERT ON tenant_modules
FOR EACH ROW
EXECUTE FUNCTION fn_tenant_modules_prevent_duplicate();
```

---

## Trigger 5
**Enunciado:** El estudiante deberá implementar un trigger que impida asignar plantillas a organizaciones cuyo estado se encuentre inactivo.

```sql
CREATE OR REPLACE FUNCTION fn_tenanttemplates_check_tenant_active()
RETURNS TRIGGER AS $$
DECLARE
    v_status VARCHAR(20);
BEGIN
    SELECT status INTO v_status
    FROM tenants
    WHERE tenant_id = NEW.tenant_id;

    IF v_status = 'inactivo' THEN
        RAISE EXCEPTION 'No se puede asignar la plantilla: la organización % se encuentra inactiva', NEW.tenant_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tenanttemplates_check_tenant_active
BEFORE INSERT ON tenanttemplates
FOR EACH ROW
EXECUTE FUNCTION fn_tenanttemplates_check_tenant_active();
```

---

## Trigger 6
**Enunciado:** El estudiante deberá implementar un trigger que valide que una persona únicamente pueda ser asociada a un cargo perteneciente a la misma organización.

```sql
CREATE OR REPLACE FUNCTION fn_persons_check_position_tenant()
RETURNS TRIGGER AS $$
DECLARE
    v_position_tenant_id INT;
BEGIN
    IF NEW.position_id IS NOT NULL THEN
        SELECT tenant_id INTO v_position_tenant_id
        FROM positions
        WHERE position_id = NEW.position_id;

        IF v_position_tenant_id IS DISTINCT FROM NEW.tenant_id THEN
            RAISE EXCEPTION 'El cargo % no pertenece a la organización %', NEW.position_id, NEW.tenant_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_persons_check_position_tenant
BEFORE INSERT OR UPDATE ON persons
FOR EACH ROW
EXECUTE FUNCTION fn_persons_check_position_tenant();
```

---

## Trigger 7
**Enunciado:** El estudiante deberá implementar un trigger que registre automáticamente la fecha de actualización cuando se produzca una modificación en una plantilla asignada a una organización.

```sql
CREATE OR REPLACE FUNCTION fn_tenanttemplates_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tenanttemplates_set_updated_at
BEFORE UPDATE ON tenanttemplates
FOR EACH ROW
EXECUTE FUNCTION fn_tenanttemplates_set_updated_at();
```

---

## Trigger 8
**Enunciado:** El estudiante deberá implementar un trigger que impida eliminar una organización cuando todavía existan personas asociadas a ella.

```sql
CREATE OR REPLACE FUNCTION fn_tenants_prevent_delete_with_persons()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM persons WHERE tenant_id = OLD.tenant_id) THEN
        RAISE EXCEPTION 'No se puede eliminar la organización %: existen personas asociadas', OLD.tenant_id;
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tenants_prevent_delete_with_persons
BEFORE DELETE ON tenants
FOR EACH ROW
EXECUTE FUNCTION fn_tenants_prevent_delete_with_persons();
```

---

## Trigger 9
**Enunciado:** El estudiante deberá implementar un trigger que impida eliminar un sistema SST cuando existan organizaciones que lo estén utilizando.

```sql
CREATE OR REPLACE FUNCTION fn_type_system_sst_prevent_delete_in_use()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM tenantsystems WHERE system_id = OLD.system_id) THEN
        RAISE EXCEPTION 'No se puede eliminar el sistema SST %: existen organizaciones que lo tienen habilitado', OLD.system_id;
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_type_system_sst_prevent_delete_in_use
BEFORE DELETE ON type_system_sst
FOR EACH ROW
EXECUTE FUNCTION fn_type_system_sst_prevent_delete_in_use();
```

---

## Trigger 10
**Enunciado:** El estudiante deberá implementar un trigger que impida eliminar un módulo cuando dicho módulo esté asignado a una o más organizaciones.

```sql
CREATE OR REPLACE FUNCTION fn_modules_prevent_delete_in_use()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM tenant_modules WHERE module_id = OLD.module_id) THEN
        RAISE EXCEPTION 'No se puede eliminar el módulo %: se encuentra asignado a una o más organizaciones', OLD.module_id;
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_modules_prevent_delete_in_use
BEFORE DELETE ON modules
FOR EACH ROW
EXECUTE FUNCTION fn_modules_prevent_delete_in_use();
```

---

## Trigger 11
**Enunciado:** El estudiante deberá implementar un trigger que valide que el porcentaje de cumplimiento calculado para una organización permanezca dentro del rango comprendido entre 0 y 100.

> El porcentaje se calcula con la misma fórmula usada en las vistas materializadas (`finalizados / total_documentos * 100`) a partir de `tenanttemplates`, recalculando después de cada `INSERT`, `UPDATE` o `DELETE` sobre esa tabla.

```sql
CREATE OR REPLACE FUNCTION fn_tenanttemplates_validate_compliance_range()
RETURNS TRIGGER AS $$
DECLARE
    v_tenant_id  INT;
    v_percentage NUMERIC;
BEGIN
    v_tenant_id := COALESCE(NEW.tenant_id, OLD.tenant_id);

    SELECT ROUND(100.0 * COUNT(*) FILTER (WHERE status = 'finalizado') / NULLIF(COUNT(*), 0), 2)
    INTO v_percentage
    FROM tenanttemplates
    WHERE tenant_id = v_tenant_id;

    IF v_percentage IS NOT NULL AND (v_percentage < 0 OR v_percentage > 100) THEN
        RAISE EXCEPTION 'El porcentaje de cumplimiento de la organización % (%) está fuera del rango permitido (0-100)',
            v_tenant_id, v_percentage;
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tenanttemplates_validate_compliance_range
AFTER INSERT OR UPDATE OR DELETE ON tenanttemplates
FOR EACH ROW
EXECUTE FUNCTION fn_tenanttemplates_validate_compliance_range();
```

---

## Trigger 12
**Enunciado:** El estudiante deberá implementar un trigger que registre en una tabla de auditoría cualquier modificación realizada sobre los datos principales de una organización.

> Se auditan los campos principales de identificación/contacto de `tenants` (`name`, `nit`, `contact_email`, `contact_phone`, `tenant_size_id`, `city_id`). El cambio de `status` se audita de forma independiente en el **Trigger 13**.

```sql
CREATE OR REPLACE FUNCTION fn_tenants_audit_main_data()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.name IS DISTINCT FROM OLD.name THEN
        INSERT INTO tenant_audit_log (tenant_id, field_name, old_value, new_value, changed_by)
        VALUES (OLD.tenant_id, 'name', OLD.name, NEW.name, current_user);
    END IF;

    IF NEW.nit IS DISTINCT FROM OLD.nit THEN
        INSERT INTO tenant_audit_log (tenant_id, field_name, old_value, new_value, changed_by)
        VALUES (OLD.tenant_id, 'nit', OLD.nit, NEW.nit, current_user);
    END IF;

    IF NEW.contact_email IS DISTINCT FROM OLD.contact_email THEN
        INSERT INTO tenant_audit_log (tenant_id, field_name, old_value, new_value, changed_by)
        VALUES (OLD.tenant_id, 'contact_email', OLD.contact_email, NEW.contact_email, current_user);
    END IF;

    IF NEW.contact_phone IS DISTINCT FROM OLD.contact_phone THEN
        INSERT INTO tenant_audit_log (tenant_id, field_name, old_value, new_value, changed_by)
        VALUES (OLD.tenant_id, 'contact_phone', OLD.contact_phone, NEW.contact_phone, current_user);
    END IF;

    IF NEW.tenant_size_id IS DISTINCT FROM OLD.tenant_size_id THEN
        INSERT INTO tenant_audit_log (tenant_id, field_name, old_value, new_value, changed_by)
        VALUES (OLD.tenant_id, 'tenant_size_id', OLD.tenant_size_id::TEXT, NEW.tenant_size_id::TEXT, current_user);
    END IF;

    IF NEW.city_id IS DISTINCT FROM OLD.city_id THEN
        INSERT INTO tenant_audit_log (tenant_id, field_name, old_value, new_value, changed_by)
        VALUES (OLD.tenant_id, 'city_id', OLD.city_id::TEXT, NEW.city_id::TEXT, current_user);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tenants_audit_main_data
AFTER UPDATE ON tenants
FOR EACH ROW
EXECUTE FUNCTION fn_tenants_audit_main_data();
```

---

## Trigger 13
**Enunciado:** El estudiante deberá implementar un trigger de auditoría que almacene el valor anterior y el nuevo valor cuando se modifique el estado de una organización.

```sql
CREATE OR REPLACE FUNCTION fn_tenants_audit_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status IS DISTINCT FROM OLD.status THEN
        INSERT INTO tenant_audit_log (tenant_id, field_name, old_value, new_value, changed_by)
        VALUES (OLD.tenant_id, 'status', OLD.status, NEW.status, current_user);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tenants_audit_status_change
AFTER UPDATE ON tenants
FOR EACH ROW
EXECUTE FUNCTION fn_tenants_audit_status_change();
```

---

## Trigger 14
**Enunciado:** El estudiante deberá implementar un trigger que registre la fecha y el usuario responsable cuando una plantilla sea modificada.

> Se utiliza `current_setting('app.current_user', true)` para tomar el usuario de aplicación si la conexión lo definió (`SET app.current_user = 'nombre_usuario';`); si no está definido, se usa `session_user` de PostgreSQL como respaldo.

```sql
CREATE OR REPLACE FUNCTION fn_tenanttemplates_set_audit_fields()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := now();
    NEW.updated_by := COALESCE(current_setting('app.current_user', true), session_user);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tenanttemplates_set_audit_fields
BEFORE UPDATE ON tenanttemplates
FOR EACH ROW
EXECUTE FUNCTION fn_tenanttemplates_set_audit_fields();
```

---

## Trigger 15
**Enunciado:** El estudiante deberá implementar un trigger que elimine o marque como inactivos los bloqueos de edición vencidos almacenados en `editing_locks`.

> Se implementa como trigger `BEFORE INSERT` sobre `editing_locks`: cada vez que se intenta crear un nuevo bloqueo, primero se marcan como inactivos (`active = FALSE`) todos los bloqueos vencidos (`expires_at < now()` y `active = TRUE`).

```sql
CREATE OR REPLACE FUNCTION fn_editing_locks_deactivate_expired()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE editing_locks
    SET active = FALSE
    WHERE active = TRUE
      AND expires_at < now();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_editing_locks_deactivate_expired
BEFORE INSERT ON editing_locks
FOR EACH ROW
EXECUTE FUNCTION fn_editing_locks_deactivate_expired();
```

---

## Notas finales

- Todos los triggers usan exclusivamente las tablas ya definidas en `base_datos_sst_pesv.md` (`tenants`, `persons`, `positions`, `type_system_sst`, `tenantsystems`, `modules`, `tenant_modules`, `tenanttemplates`, `editing_locks`, `tenant_audit_log`); no se crean tablas nuevas.
- Los **Triggers 7 y 14** actúan ambos sobre `tenanttemplates` antes de un `UPDATE`: el 7 solo actualiza `updated_at` (según el enunciado exacto de ese punto) y el 14 actualiza `updated_at` **y** `updated_by` (según su propio enunciado). Ambos pueden coexistir sin conflicto, ya que solo escriben sobre campos de auditoría.
- Los **Triggers 12 y 13** son independientes: el 12 audita los datos principales de contacto/identificación de `tenants`, y el 13 audita específicamente los cambios de `status`, ambos insertando en `tenant_audit_log`.
- Antes de ejecutar los `CREATE TRIGGER`, las tablas y datos de prueba de `base_datos_sst_pesv.md` deben existir ya en la base de datos.
