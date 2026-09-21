-- 1. sp_registrar_tenant: registra una nueva organización, validando previamente que no exista otra con el mismo NIT.
CREATE OR REPLACE PROCEDURE sp_registrar_tenant(
    p_tenant_size_id INT,
    p_municipality_id INT,
    p_name VARCHAR(150),
    p_nit VARCHAR(20),
    p_contact_email VARCHAR(150),
    p_contact_phone VARCHAR(30),
    p_address TEXT,
    p_is_active BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM tenants WHERE nit = p_nit) THEN
        RAISE EXCEPTION 'Ya existe una organización registrada con el NIT: %', p_nit;
    END IF;

    INSERT INTO tenants (tenant_size_id, municipality_id, name, nit, contact_email, contact_phone, address, is_active)
    VALUES (p_tenant_size_id, p_municipality_id, p_name, p_nit, p_contact_email, p_contact_phone, p_address, p_is_active);

    COMMIT;
END;
$$;

-- 2. sp_registrar_person: registra una nueva persona y la asocia a una organización y a un cargo determinado, validando que la organización exista y esté activa.
CREATE OR REPLACE PROCEDURE sp_registrar_person(
    p_position_id INT,
    p_first_name VARCHAR(80),
    p_last_name VARCHAR(80),
    p_email VARCHAR(150),
    p_document_number VARCHAR(30),
    p_is_active BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_tenant_id INT;
    v_tenant_active BOOLEAN;
BEGIN
    -- Validar existencia y estado de position para obtener el tenant
    SELECT t.id, t.is_active INTO v_tenant_id, v_tenant_active
    FROM positions pos
    INNER JOIN tenants t ON pos.tenant_id = t.id
    WHERE pos.id = p_position_id;

    IF v_tenant_id IS NULL THEN
        RAISE EXCEPTION 'El cargo con ID % no existe.', p_position_id;
    END IF;

    IF NOT v_tenant_active THEN
        RAISE EXCEPTION 'La organización asociada al cargo % está inactiva y no puede recibir nuevos usuarios.', p_position_id;
    END IF;

    INSERT INTO persons (position_id, first_name, last_name, email, document_number, is_active)
    VALUES (p_position_id, p_first_name, p_last_name, p_email, p_document_number, p_is_active);

    COMMIT;
END;
$$;

-- 3. sp_cambiar_estado_tenant: cambia el estado de una organización entre activa e inactiva, recibiendo el tenant_id y el nuevo estado booleano.
CREATE OR REPLACE PROCEDURE sp_cambiar_estado_tenant(
    p_tenant_id INT,
    p_is_active BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tenants WHERE id = p_tenant_id) THEN
        RAISE EXCEPTION 'La organización con ID % no existe.', p_tenant_id;
    END IF;

    UPDATE tenants
    SET is_active = p_is_active,
        updated_at = NOW()
    WHERE id = p_tenant_id;

    COMMIT;
END;
$$;

-- 4. sp_asignar_modulo_tenant: asigna un módulo a una organización, validando que no exista ya esa asignación (evitando duplicados).
CREATE OR REPLACE PROCEDURE sp_asignar_modulo_tenant(
    p_tenant_id INT,
    p_module_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM tenant_modules WHERE tenant_id = p_tenant_id AND module_id = p_module_id) THEN
        RAISE EXCEPTION 'El módulo % ya se encuentra asignado a la organización %.', p_module_id, p_tenant_id;
    END IF;

    INSERT INTO tenant_modules (tenant_id, module_id, is_active)
    VALUES (p_tenant_id, p_module_id, TRUE);

    COMMIT;
END;
$$;

-- 5. sp_habilitar_sistema_tenant: habilita un sistema SST para una organización determinada, validando que no esté ya habilitado.
CREATE OR REPLACE PROCEDURE sp_habilitar_sistema_tenant(
    p_tenant_id INT,
    p_type_system_sst_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM tenantsystems WHERE tenant_id = p_tenant_id AND type_system_sst_id = p_type_system_sst_id) THEN
        RAISE EXCEPTION 'El sistema SST % ya se encuentra habilitado para la organización %.', p_type_system_sst_id, p_tenant_id;
    END IF;

    INSERT INTO tenantsystems (tenant_id, type_system_sst_id, is_active)
    VALUES (p_tenant_id, p_type_system_sst_id, TRUE);

    COMMIT;
END;
$$;

/*
==============================================================================
EJEMPLOS DE INVOCACIÓN (Para uso manual mediante CALL)
==============================================================================

-- Registrar un nuevo tenant
-- CALL sp_registrar_tenant(1, 3, 'Nueva Empresa SAS', '901234567-8', 'gerencia@nuevaempresa.com', '3000000000', 'Calle 100', TRUE);

-- Registrar una nueva persona
-- CALL sp_registrar_person(1, 'Juan', 'Pérez', 'jperez@tecnivalle.com', '1234567890', TRUE);

-- Cambiar estado a inactivo
-- CALL sp_cambiar_estado_tenant(2, FALSE);

-- Asignar módulo al tenant (ej. Modulo 5 al Tenant 1)
-- CALL sp_asignar_modulo_tenant(1, 5);

-- Habilitar sistema SST al tenant (ej. Sistema 2 al Tenant 1)
-- CALL sp_habilitar_sistema_tenant(1, 2);

==============================================================================
*/
