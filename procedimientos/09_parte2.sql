-- 1. sp_asignar_plantilla_tenant: asigna una plantilla a una organización indicando sistema y etapa PHVA (implícito en la plantilla).
CREATE OR REPLACE PROCEDURE sp_asignar_plantilla_tenant(
    p_tenant_id INT,
    p_template_id INT,
    p_format_sst_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM templates WHERE id = p_template_id) THEN
        RAISE EXCEPTION 'La plantilla con ID % no existe.', p_template_id;
    END IF;

    IF EXISTS (SELECT 1 FROM tenant_templates WHERE tenant_id = p_tenant_id AND template_id = p_template_id) THEN
        RAISE EXCEPTION 'La plantilla % ya está asignada a la organización %.', p_template_id, p_tenant_id;
    END IF;

    INSERT INTO tenant_templates (tenant_id, template_id, format_sst_id)
    VALUES (p_tenant_id, p_template_id, p_format_sst_id);

    COMMIT;
END;
$$;

-- 2. sp_cambiar_cargo_person: cambia el cargo de una persona dentro de una organización.
CREATE OR REPLACE PROCEDURE sp_cambiar_cargo_person(
    p_person_id INT,
    p_new_position_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM persons WHERE id = p_person_id) THEN
        RAISE EXCEPTION 'La persona con ID % no existe.', p_person_id;
    END IF;

    UPDATE persons
    SET position_id = p_new_position_id,
        updated_at = NOW()
    WHERE id = p_person_id;

    COMMIT;
END;
$$;

-- 3. sp_trasladar_person: traslada una persona de una organización a otra, actualizando tenant_id y previniendo duplicados de correo.
CREATE OR REPLACE PROCEDURE sp_trasladar_person(
    p_person_id INT,
    p_new_position_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_person_email VARCHAR(150);
    v_new_tenant_id INT;
    v_tenant_active BOOLEAN;
BEGIN
    -- Validar que la persona existe y obtener su correo
    SELECT email INTO v_person_email
    FROM persons
    WHERE id = p_person_id;

    IF v_person_email IS NULL THEN
        RAISE EXCEPTION 'La persona con ID % no existe.', p_person_id;
    END IF;

    -- Obtener el nuevo tenant desde la posición
    SELECT t.id, t.is_active INTO v_new_tenant_id, v_tenant_active
    FROM positions pos
    INNER JOIN tenants t ON pos.tenant_id = t.id
    WHERE pos.id = p_new_position_id;

    IF v_new_tenant_id IS NULL THEN
        RAISE EXCEPTION 'El cargo destino con ID % no existe.', p_new_position_id;
    ELSIF NOT v_tenant_active THEN
        RAISE EXCEPTION 'La organización destino está inactiva y no puede recibir personal.';
    END IF;

    -- Actualizar el cargo (y por ende el tenant) de la persona
    UPDATE persons
    SET position_id = p_new_position_id,
        updated_at = NOW()
    WHERE id = p_person_id;

    COMMIT;
END;
$$;

-- 4. sp_deshabilitar_modulos_tenant_inactivo: deshabilita (is_active = false) todos los módulos de una organización inactiva.
CREATE OR REPLACE PROCEDURE sp_deshabilitar_modulos_tenant_inactivo(
    p_tenant_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_tenant_active BOOLEAN;
BEGIN
    SELECT is_active INTO v_tenant_active
    FROM tenants
    WHERE id = p_tenant_id;

    IF v_tenant_active IS NULL THEN
        RAISE EXCEPTION 'La organización con ID % no existe.', p_tenant_id;
    ELSIF v_tenant_active THEN
        RAISE EXCEPTION 'No se puede ejecutar esta acción sobre una organización activa. Debe inhabilitarla primero.';
    END IF;

    UPDATE tenant_modules
    SET is_active = FALSE,
        updated_at = NOW()
    WHERE tenant_id = p_tenant_id;

    COMMIT;
END;
$$;

-- 5. sp_eliminar_asignacion_modulo: elimina controladamente una asignación de módulo, previniendo su eliminación si tiene plantillas asociadas en uso.
CREATE OR REPLACE PROCEDURE sp_eliminar_asignacion_modulo(
    p_tenant_id INT,
    p_module_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validar que exista la asignación
    IF NOT EXISTS (SELECT 1 FROM tenant_modules WHERE tenant_id = p_tenant_id AND module_id = p_module_id) THEN
        RAISE EXCEPTION 'La organización % no tiene asignado el módulo %.', p_tenant_id, p_module_id;
    END IF;

    -- Validar si existen registros dependientes (tenant_templates asociadas a plantillas de ese módulo)
    IF EXISTS (
        SELECT 1
        FROM tenant_templates tt
        INNER JOIN templates temp ON tt.template_id = temp.id
        WHERE tt.tenant_id = p_tenant_id AND temp.module_id = p_module_id
    ) THEN
        RAISE EXCEPTION 'No se puede eliminar la asignación del módulo % a la organización % porque existen plantillas documentales asociadas a este módulo asignadas al tenant.', p_module_id, p_tenant_id;
    END IF;

    DELETE FROM tenant_modules
    WHERE tenant_id = p_tenant_id AND module_id = p_module_id;

    COMMIT;
END;
$$;

/*
==============================================================================
EJEMPLOS DE INVOCACIÓN (Para uso manual mediante CALL)
==============================================================================

-- Asignar una plantilla
-- CALL sp_asignar_plantilla_tenant(1, 1, 1);

-- Cambiar cargo de una persona (ej. id persona 1 al cargo 2)
-- CALL sp_cambiar_cargo_person(1, 2);

-- Trasladar persona a otra organización (ej. id persona 1 al cargo 4, que es de otra org)
-- CALL sp_trasladar_person(1, 4);

-- Deshabilitar módulos de tenant inactivo (ej. tenant 4 que está inactivo)
-- CALL sp_deshabilitar_modulos_tenant_inactivo(4);

-- Eliminar asignación de módulo (ej. Modulo 8 al Tenant 4)
-- CALL sp_eliminar_asignacion_modulo(4, 8);

==============================================================================
*/
