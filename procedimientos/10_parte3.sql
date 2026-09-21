-- 1. sp_contar_plantillas_tenant: determina el número total de plantillas asociadas a una organización y lo muestra con RAISE NOTICE.
CREATE OR REPLACE PROCEDURE sp_contar_plantillas_tenant(
    p_tenant_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total INT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tenants WHERE id = p_tenant_id) THEN
        RAISE EXCEPTION 'La organización con ID % no existe.', p_tenant_id;
    END IF;

    SELECT COUNT(id) INTO v_total
    FROM tenant_templates
    WHERE tenant_id = p_tenant_id;

    RAISE NOTICE 'La organización con ID % tiene un total de % plantillas asignadas.', p_tenant_id, v_total;
    
    COMMIT;
END;
$$;

-- 2. sp_calcular_cumplimiento_tenant: determina el porcentaje de cumplimiento documental (finalizados vs totales) y lo muestra con RAISE NOTICE.
CREATE OR REPLACE PROCEDURE sp_calcular_cumplimiento_tenant(
    p_tenant_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total INT;
    v_finalizados INT;
    v_porcentaje NUMERIC;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tenants WHERE id = p_tenant_id) THEN
        RAISE EXCEPTION 'La organización con ID % no existe.', p_tenant_id;
    END IF;

    SELECT COUNT(id), 
           COUNT(id) FILTER (WHERE status = 'finalizado')
    INTO v_total, v_finalizados
    FROM tenant_templates
    WHERE tenant_id = p_tenant_id;

    IF v_total = 0 THEN
        v_porcentaje := 0;
    ELSE
        v_porcentaje := ROUND((v_finalizados * 100.0) / v_total, 2);
    END IF;

    RAISE NOTICE 'Organización %: Total Documentos: %, Finalizados: %, Cumplimiento: %%%', 
                 p_tenant_id, v_total, COALESCE(v_finalizados, 0), v_porcentaje;

    COMMIT;
END;
$$;

-- 3. sp_contar_documentos_por_etapa: determina la cantidad de documentos correspondientes a una organización y una etapa PHVA específica.
CREATE OR REPLACE PROCEDURE sp_contar_documentos_por_etapa(
    p_tenant_id INT,
    p_stage_phva_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total INT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tenants WHERE id = p_tenant_id) THEN
        RAISE EXCEPTION 'La organización con ID % no existe.', p_tenant_id;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM stages_phva WHERE id = p_stage_phva_id) THEN
        RAISE EXCEPTION 'La etapa PHVA con ID % no existe.', p_stage_phva_id;
    END IF;

    SELECT COUNT(tt.id) INTO v_total
    FROM tenant_templates tt
    INNER JOIN templates temp ON tt.template_id = temp.id
    WHERE tt.tenant_id = p_tenant_id AND temp.stage_phva_id = p_stage_phva_id;

    RAISE NOTICE 'Organización ID % en la etapa PHVA ID % tiene % documentos asignados.', p_tenant_id, p_stage_phva_id, v_total;

    COMMIT;
END;
$$;

-- 4. sp_actualizar_contacto_tenant: modifica simultáneamente ambos datos de contacto de la organización y actualiza updated_at.
CREATE OR REPLACE PROCEDURE sp_actualizar_contacto_tenant(
    p_tenant_id INT,
    p_contact_email VARCHAR(150),
    p_contact_phone VARCHAR(30)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tenants WHERE id = p_tenant_id) THEN
        RAISE EXCEPTION 'La organización con ID % no existe.', p_tenant_id;
    END IF;

    UPDATE tenants
    SET contact_email = p_contact_email,
        contact_phone = p_contact_phone,
        updated_at = NOW()
    WHERE id = p_tenant_id;

    COMMIT;
END;
$$;

-- 5. sp_asignar_plantilla_segura: asigna una plantilla utilizando un bloque BEGIN...EXCEPTION para capturar errores inesperados de forma segura.
CREATE OR REPLACE PROCEDURE sp_asignar_plantilla_segura(
    p_tenant_id INT,
    p_template_id INT,
    p_format_sst_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Intentamos ejecutar la inserción normalmente
    INSERT INTO tenant_templates (tenant_id, template_id, format_sst_id)
    VALUES (p_tenant_id, p_template_id, p_format_sst_id);
    
    -- Si tiene éxito, confirmamos
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        -- Si falla (ej. FK inválida, registro duplicado), atrapamos el error original
        RAISE NOTICE 'Ocurrió un error inesperado al asignar la plantilla: %', SQLERRM;
        
        -- Nota sobre el ROLLBACK explícito en PostgreSQL:
        -- En PL/pgSQL, los bloques EXCEPTION definen automáticamente un punto de guardado (savepoint).
        -- Cuando se captura una excepción, el motor revierte automáticamente la subtransacción interna.
        -- Incluir la palabra "ROLLBACK;" explícitamente dentro del bloque EXCEPTION lanzará un error:
        -- "cannot commit or rollback in a context with an exception handler".
        -- Por tanto, el motor ya ha hecho el rollback por nosotros, lo dejamos comentado para cumplir
        -- estrictamente tu regla lógica sin romper la ejecución en PostgreSQL 16.
        -- ROLLBACK;
END;
$$;

/*
==============================================================================
EJEMPLOS DE INVOCACIÓN (Para uso manual mediante CALL)
==============================================================================

-- Mostrar el conteo de plantillas en consola
-- CALL sp_contar_plantillas_tenant(1);

-- Mostrar el porcentaje de cumplimiento en consola
-- CALL sp_calcular_cumplimiento_tenant(2);

-- Contar documentos de una organización (Tenant 2) en una etapa PHVA específica (Hacer = 2)
-- CALL sp_contar_documentos_por_etapa(2, 2);

-- Actualizar contacto de organización
-- CALL sp_actualizar_contacto_tenant(1, 'nuevo_gerente@tecnivalle.com', '3101112233');

-- Ejecución SEGURA de asignación correcta
-- CALL sp_asignar_plantilla_segura(1, 15, NULL);

-- Ejecución SEGURA fallida para probar la captura de EXCEPTION (template 999 no existe en BD)
-- CALL sp_asignar_plantilla_segura(1, 999, NULL);

==============================================================================
*/
