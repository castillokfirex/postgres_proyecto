-- 1. fn_total_personas_tenant: recibe tenant_id, retorna un entero con la cantidad total de personas asociadas a esa organización.
CREATE OR REPLACE FUNCTION fn_total_personas_tenant(p_tenant_id INT)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_total INT;
BEGIN
    SELECT COUNT(p.id) INTO v_total
    FROM persons p
    INNER JOIN positions pos ON p.position_id = pos.id
    WHERE pos.tenant_id = p_tenant_id;
    
    RETURN v_total;
END;
$$;
-- Ejemplo de uso:
-- SELECT fn_total_personas_tenant(1);


-- 2. fn_porcentaje_cumplimiento_tenant: recibe tenant_id, retorna un numérico con el porcentaje de cumplimiento documental.
CREATE OR REPLACE FUNCTION fn_porcentaje_cumplimiento_tenant(p_tenant_id INT)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_total INT;
    v_finalizados INT;
BEGIN
    SELECT COUNT(id), 
           COUNT(id) FILTER (WHERE status = 'finalizado')
    INTO v_total, v_finalizados
    FROM tenant_templates
    WHERE tenant_id = p_tenant_id;

    IF v_total = 0 THEN
        RETURN 0.00;
    ELSE
        RETURN ROUND((v_finalizados * 100.0) / v_total, 2);
    END IF;
END;
$$;
-- Ejemplo de uso:
-- SELECT fn_porcentaje_cumplimiento_tenant(2);


-- 3. fn_tenant_tiene_modulo: recibe tenant_id y module_id, retorna un booleano indicando si esa organización tiene ese módulo habilitado.
CREATE OR REPLACE FUNCTION fn_tenant_tiene_modulo(p_tenant_id INT, p_module_id INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_existe BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 
        FROM tenant_modules 
        WHERE tenant_id = p_tenant_id 
          AND module_id = p_module_id 
          AND is_active = true
    ) INTO v_existe;
    
    RETURN v_existe;
END;
$$;
-- Ejemplo de uso:
-- SELECT fn_tenant_tiene_modulo(1, 1);


-- 4. fn_nombre_completo_persona: recibe person_id, retorna un VARCHAR con el nombre completo.
CREATE OR REPLACE FUNCTION fn_nombre_completo_persona(p_person_id INT)
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
DECLARE
    v_nombre_completo VARCHAR;
BEGIN
    SELECT first_name || ' ' || last_name INTO v_nombre_completo
    FROM persons
    WHERE id = p_person_id;
    
    RETURN v_nombre_completo;
END;
$$;
-- Ejemplo de uso:
-- SELECT fn_nombre_completo_persona(1);


-- 5. fn_total_plantillas_etapa: recibe tenant_id y stage_phva_id, retorna un entero con la cantidad de plantillas de esa organización en esa etapa PHVA.
CREATE OR REPLACE FUNCTION fn_total_plantillas_etapa(p_tenant_id INT, p_stage_phva_id INT)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_total INT;
BEGIN
    SELECT COUNT(tt.id) INTO v_total
    FROM tenant_templates tt
    INNER JOIN templates temp ON tt.template_id = temp.id
    WHERE tt.tenant_id = p_tenant_id 
      AND temp.stage_phva_id = p_stage_phva_id;
      
    RETURN v_total;
END;
$$;
-- Ejemplo de uso:
-- SELECT fn_total_plantillas_etapa(1, 2);


-- 6. fn_modulos_habilitados_tenant: función tabular que recibe tenant_id y retorna todos los módulos habilitados para esa organización.
CREATE OR REPLACE FUNCTION fn_modulos_habilitados_tenant(p_tenant_id INT)
RETURNS TABLE (
    module_id INT,
    module_title VARCHAR,
    system_name VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT m.id, m.title::VARCHAR, sys.name::VARCHAR
    FROM tenant_modules tm
    INNER JOIN modules m ON tm.module_id = m.id
    INNER JOIN type_system_sst sys ON m.type_system_sst_id = sys.id
    WHERE tm.tenant_id = p_tenant_id AND tm.is_active = true;
END;
$$;
-- Ejemplo de uso (Notar que se usa como una tabla en el FROM):
-- SELECT * FROM fn_modulos_habilitados_tenant(2);


-- 7. fn_personas_cargos_tenant: función tabular que recibe tenant_id y retorna las personas de esa organización junto con sus cargos.
CREATE OR REPLACE FUNCTION fn_personas_cargos_tenant(p_tenant_id INT)
RETURNS TABLE (
    person_id INT,
    first_name VARCHAR,
    last_name VARCHAR,
    position_name VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT p.id, p.first_name::VARCHAR, p.last_name::VARCHAR, pos.name::VARCHAR
    FROM persons p
    INNER JOIN positions pos ON p.position_id = pos.id
    WHERE pos.tenant_id = p_tenant_id;
END;
$$;
-- Ejemplo de uso (Notar que se usa como una tabla en el FROM):
-- SELECT * FROM fn_personas_cargos_tenant(1);


-- 8. fn_clasificar_cumplimiento: recibe un porcentaje NUMERIC, retorna un VARCHAR clasificando como Bajo, Medio o Alto.
CREATE OR REPLACE FUNCTION fn_clasificar_cumplimiento(p_porcentaje NUMERIC)
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_porcentaje < 40 THEN
        RETURN 'Bajo';
    ELSIF p_porcentaje >= 40 AND p_porcentaje < 80 THEN
        RETURN 'Medio';
    ELSE
        RETURN 'Alto';
    END IF;
END;
$$;
-- Ejemplo de uso:
-- SELECT fn_clasificar_cumplimiento(85.50);
-- También se puede usar dentro de un query mayor:
-- SELECT id, name, fn_clasificar_cumplimiento(fn_porcentaje_cumplimiento_tenant(id)) AS clasificacion FROM tenants;
