-- ==========================================
-- CONSULTAS BÁSICAS
-- ==========================================

-- 1. Selecciona todos los registros de la tabla tenants.
SELECT * FROM tenants;

-- 2. Selecciona nombre, correo y teléfono de contacto de los tenants.
SELECT name, contact_email, contact_phone FROM tenants;

-- 3. Selecciona nombre, apellido y correo de las personas.
SELECT first_name, last_name, email FROM persons;

-- 4. Selecciona todas las personas con estado 'activo'.
SELECT * FROM persons WHERE status = 'activo';

-- 5. Busca tenants cuyo nombre contenga la palabra 'palabra'.
SELECT * FROM tenants WHERE name ILIKE '%palabra%';

-- 6. Selecciona todos los países ordenados por nombre.
SELECT * FROM countries ORDER BY name;

-- 7. Selecciona todos los departamentos/estados pertenecientes al país con ID 1.
SELECT * FROM states WHERE country_id = 1;

-- 8. Selecciona todas las ciudades pertenecientes al estado/departamento con ID 1.
SELECT * FROM cities WHERE state_id = 1;

-- 9. Selecciona todos los cargos ordenados por descripción.
SELECT * FROM positions ORDER BY description;

-- 10. Selecciona todas las personas asociadas al tenant con ID 1.
SELECT * FROM persons WHERE tenant_id = 1;

-- 11. Selecciona todos los tenants con estado 'activo'.
SELECT * FROM tenants WHERE status = 'activo';

-- 12. Selecciona los tenants creados entre el 1 de enero de 2024 y el 31 de diciembre de 2026.
SELECT * FROM tenants WHERE created_at BETWEEN '2024-01-01' AND '2026-12-31';

-- 13. Selecciona todos los tamaños de empresa (tenant_sizes).
SELECT * FROM tenant_sizes;

-- 14. Selecciona todos los tipos de sistemas SST.
SELECT * FROM type_system_sst;

-- 15. Selecciona el título, descripción y orden de los módulos, ordenados por su display_order.
SELECT title, description, display_order FROM modules ORDER BY display_order;


-- ==========================================
-- CONSULTAS INTERMEDIAS
-- ==========================================

-- 16. Obtiene el nombre completo de las personas y el nombre de su organización.
SELECT p.first_name, p.last_name, t.name AS organizacion
FROM persons p
JOIN tenants t ON t.tenant_id = p.tenant_id;

-- 17. Obtiene el nombre completo de las personas y la descripción de su cargo.
SELECT p.first_name, p.last_name, pos.description AS cargo
FROM persons p
JOIN positions pos ON pos.position_id = p.position_id;

-- 18. Obtiene el nombre de los tenants y la descripción de su tamaño.
SELECT t.name, ts.name AS tamano_empresa
FROM tenants t
JOIN tenant_sizes ts ON ts.tenant_size_id = t.tenant_size_id;

-- 19. Obtiene la ubicación completa (ciudad, departamento, país) de cada tenant.
SELECT t.name, c.name AS ciudad, s.name AS departamento, co.name AS pais
FROM tenants t
JOIN cities c ON c.city_id = t.city_id
JOIN states s ON s.state_id = c.state_id
JOIN countries co ON co.country_id = s.country_id;

-- 20. Cuenta el total de personas asociadas a cada tenant.
SELECT t.name, COUNT(p.person_id) AS total_personas
FROM tenants t
LEFT JOIN persons p ON p.tenant_id = t.tenant_id
GROUP BY t.tenant_id, t.name;

-- 21. Obtiene los tenants que tienen más de 3 personas asociadas.
SELECT t.name, COUNT(p.person_id) AS total_personas
FROM tenants t
JOIN persons p ON p.tenant_id = t.tenant_id
GROUP BY t.tenant_id, t.name
HAVING COUNT(p.person_id) > 3;

-- 22. Obtiene los módulos asignados a cada organización.
SELECT t.name AS organizacion, m.title AS modulo
FROM tenant_modules tm
JOIN tenants t ON t.tenant_id = tm.tenant_id
JOIN modules m ON m.module_id = tm.module_id;

-- 23. Cuenta el total de módulos asignados a cada tenant.
SELECT t.name, COUNT(tm.module_id) AS total_modulos
FROM tenants t
JOIN tenant_modules tm ON tm.tenant_id = t.tenant_id
GROUP BY t.tenant_id, t.name;

-- 24. Obtiene los sistemas SST habilitados para cada organización.
SELECT t.name AS organizacion, s.name AS sistema
FROM tenantsystems tsy
JOIN tenants t ON t.tenant_id = tsy.tenant_id
JOIN type_system_sst s ON s.system_id = tsy.system_id;

-- 25. Obtiene el sistema al que pertenece cada módulo.
SELECT m.title AS modulo, s.name AS sistema
FROM modules m
JOIN type_system_sst s ON s.system_id = m.system_id;

-- 26. Obtiene los formatos asociados a cada módulo.
SELECT f.name AS formato, m.title AS modulo
FROM formats_sst f
JOIN modules m ON m.module_id = f.module_id;

-- 27. Cuenta la cantidad total de formatos por cada módulo.
SELECT m.title AS modulo, COUNT(f.format_id) AS total_formatos
FROM modules m
JOIN formats_sst f ON f.module_id = m.module_id
GROUP BY m.module_id, m.title;

-- 28. Obtiene las plantillas asignadas a cada tenant.
SELECT t.name AS organizacion, tt.template_id
FROM tenanttemplates tt
JOIN tenants t ON t.tenant_id = tt.tenant_id;

-- 29. Obtiene el sistema y la etapa PHVA de cada plantilla asignada a los tenants.
SELECT t.name AS organizacion, s.name AS sistema, ph.name AS etapa_phva
FROM tenanttemplates tt
JOIN tenants t ON t.tenant_id = tt.tenant_id
JOIN type_system_sst s ON s.system_id = tt.system_id
JOIN phva_stages ph ON ph.phva_stage_id = tt.phva_stage_id;

-- 30. Cuenta el total de plantillas asignadas a cada tenant.
SELECT t.name, COUNT(tt.template_id) AS total_plantillas
FROM tenants t
JOIN tenanttemplates tt ON tt.tenant_id = t.tenant_id
GROUP BY t.tenant_id, t.name;

-- 31. Obtiene los tenants que no tienen ninguna persona asociada.
SELECT t.*
FROM tenants t
LEFT JOIN persons p ON p.tenant_id = t.tenant_id
WHERE p.person_id IS NULL;

-- 32. Obtiene los módulos que no han sido asignados a ningún tenant.
SELECT m.*
FROM modules m
LEFT JOIN tenant_modules tm ON tm.module_id = m.module_id
WHERE tm.tenant_module_id IS NULL;

-- 33. Cuenta la cantidad de plantillas por cada etapa del ciclo PHVA.
SELECT ph.name AS etapa_phva, COUNT(tt.template_id) AS total_plantillas
FROM phva_stages ph
LEFT JOIN tenanttemplates tt ON tt.phva_stage_id = ph.phva_stage_id
GROUP BY ph.phva_stage_id, ph.name;

-- 34. Cuenta el total de organizaciones por ciudad.
SELECT c.name AS ciudad, COUNT(t.tenant_id) AS total_organizaciones
FROM cities c
JOIN tenants t ON t.city_id = c.city_id
GROUP BY c.city_id, c.name;

-- 35. Cuenta la cantidad de personas por cada cargo dentro de cada organización.
SELECT t.name AS organizacion, pos.description AS cargo, COUNT(p.person_id) AS total_personas
FROM tenants t
JOIN positions pos ON pos.tenant_id = t.tenant_id
LEFT JOIN persons p ON p.position_id = pos.position_id
GROUP BY t.tenant_id, t.name, pos.position_id, pos.description;


-- ==========================================
-- CONSULTAS AVANZADAS
-- ==========================================

-- 36. Obtiene el tenant con la mayor cantidad de personas asociadas.
SELECT t.name, COUNT(p.person_id) AS total_personas
FROM tenants t
JOIN persons p ON p.tenant_id = t.tenant_id
GROUP BY t.tenant_id, t.name
ORDER BY total_personas DESC
LIMIT 1;

-- 37. Obtiene los tenants cuya cantidad de personas es mayor al promedio.
WITH conteo AS (
    SELECT tenant_id, COUNT(*) AS total
    FROM persons
    GROUP BY tenant_id
)
SELECT t.name, c.total
FROM tenants t
JOIN conteo c ON c.tenant_id = t.tenant_id
WHERE c.total > (SELECT AVG(total) FROM conteo);

-- 38. Obtiene las organizaciones que tienen asignados todos los módulos de un sistema específico.
SELECT t.name AS organizacion, m.system_id
FROM tenant_modules tm
JOIN tenants t ON t.tenant_id = tm.tenant_id
JOIN modules m ON m.module_id = tm.module_id
GROUP BY t.tenant_id, t.name, m.system_id
HAVING COUNT(DISTINCT tm.module_id) = (
    SELECT COUNT(*) FROM modules WHERE system_id = m.system_id
);

-- 39. Obtiene las organizaciones que tienen módulos asignados pero no tienen plantillas.
SELECT DISTINCT t.tenant_id, t.name
FROM tenants t
JOIN tenant_modules tm ON tm.tenant_id = t.tenant_id
WHERE NOT EXISTS (
    SELECT 1 FROM tenanttemplates tt WHERE tt.tenant_id = t.tenant_id
);

-- 40. Obtiene los tenants que tienen plantillas en todas las etapas del ciclo PHVA.
SELECT t.tenant_id, t.name
FROM tenants t
JOIN tenanttemplates tt ON tt.tenant_id = t.tenant_id
GROUP BY t.tenant_id, t.name
HAVING COUNT(DISTINCT tt.phva_stage_id) = (SELECT COUNT(*) FROM phva_stages);

-- 41. Cuenta el total de plantillas por etapa PHVA para cada organización.
SELECT t.name, ph.name AS etapa, COUNT(*) AS total
FROM tenanttemplates tt
JOIN tenants t ON t.tenant_id = tt.tenant_id
JOIN phva_stages ph ON ph.phva_stage_id = tt.phva_stage_id
GROUP BY t.tenant_id, t.name, ph.name
ORDER BY t.name, ph.name;

-- 42. Pivotea el recuento de plantillas por cada etapa del ciclo PHVA para cada tenant.
SELECT t.name,
    COUNT(*) FILTER (WHERE ph.name = 'Planear')   AS planear,
    COUNT(*) FILTER (WHERE ph.name = 'Hacer')      AS hacer,
    COUNT(*) FILTER (WHERE ph.name = 'Verificar')  AS verificar,
    COUNT(*) FILTER (WHERE ph.name = 'Actuar')     AS actuar
FROM tenanttemplates tt
JOIN tenants t ON t.tenant_id = tt.tenant_id
JOIN phva_stages ph ON ph.phva_stage_id = tt.phva_stage_id
GROUP BY t.tenant_id, t.name;

-- 43. Calcula el porcentaje de plantillas en cada etapa respecto al total por tenant.
SELECT t.name, ph.name AS etapa, COUNT(*) AS total,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY t.tenant_id), 2) AS porcentaje
FROM tenanttemplates tt
JOIN tenants t ON t.tenant_id = tt.tenant_id
JOIN phva_stages ph ON ph.phva_stage_id = tt.phva_stage_id
GROUP BY t.tenant_id, t.name, ph.name;

-- 44. Obtiene la etapa PHVA con más plantillas para cada organización usando funciones de ventana.
WITH conteo AS (
    SELECT t.tenant_id, t.name, ph.name AS etapa, COUNT(*) AS total,
        ROW_NUMBER() OVER (PARTITION BY t.tenant_id ORDER BY COUNT(*) DESC) AS rn
    FROM tenanttemplates tt
    JOIN tenants t ON t.tenant_id = tt.tenant_id
    JOIN phva_stages ph ON ph.phva_stage_id = tt.phva_stage_id
    GROUP BY t.tenant_id, t.name, ph.name
)
SELECT tenant_id, name, etapa, total
FROM conteo
WHERE rn = 1;

-- 45. Unifica el resumen de documentos de SST y PESV indicando de qué sistema proviene.
SELECT tenant_id, tenant_name, total_documentos, finalizados, porcentaje_cumplimiento, 'SST' AS sistema
FROM vm_template_sst_docs_summary
UNION ALL
SELECT tenant_id, tenant_name, total_documentos, finalizados, porcentaje_cumplimiento, 'PESV' AS sistema
FROM vm_template_pesv_docs_summary;

-- 46. Identifica organizaciones cuyo cumplimiento está por debajo del promedio global de sistemas SST y PESV.
WITH resumen AS (
    SELECT tenant_id, tenant_name, porcentaje_cumplimiento FROM vm_template_sst_docs_summary
    UNION ALL
    SELECT tenant_id, tenant_name, porcentaje_cumplimiento FROM vm_template_pesv_docs_summary
)
SELECT *
FROM resumen
WHERE porcentaje_cumplimiento < (SELECT AVG(porcentaje_cumplimiento) FROM resumen);

-- 47. Clasifica el nivel de cumplimiento de los tenants (Bajo, Medio, Alto).
WITH resumen AS (
    SELECT tenant_id, tenant_name, porcentaje_cumplimiento FROM vm_template_sst_docs_summary
    UNION ALL
    SELECT tenant_id, tenant_name, porcentaje_cumplimiento FROM vm_template_pesv_docs_summary
)
SELECT tenant_id, tenant_name, porcentaje_cumplimiento,
    CASE
        WHEN porcentaje_cumplimiento < 40 THEN 'Bajo'
        WHEN porcentaje_cumplimiento < 70 THEN 'Medio'
        ELSE 'Alto'
    END AS nivel_cumplimiento
FROM resumen;

-- 48. Establece un ranking de las organizaciones según su porcentaje de cumplimiento.
WITH resumen AS (
    SELECT tenant_id, tenant_name, porcentaje_cumplimiento FROM vm_template_sst_docs_summary
    UNION ALL
    SELECT tenant_id, tenant_name, porcentaje_cumplimiento FROM vm_template_pesv_docs_summary
)
SELECT tenant_id, tenant_name, porcentaje_cumplimiento,
    RANK() OVER (ORDER BY porcentaje_cumplimiento DESC) AS ranking
FROM resumen;

-- 49. Calcula la diferencia del porcentaje de cumplimiento de cada tenant frente al promedio general.
WITH resumen AS (
    SELECT tenant_id, tenant_name, porcentaje_cumplimiento FROM vm_template_sst_docs_summary
    UNION ALL
    SELECT tenant_id, tenant_name, porcentaje_cumplimiento FROM vm_template_pesv_docs_summary
)
SELECT tenant_id, tenant_name, porcentaje_cumplimiento,
    porcentaje_cumplimiento - AVG(porcentaje_cumplimiento) OVER () AS diferencia_promedio
FROM resumen;

-- 50. Calcula el acumulado de plantillas finalizadas por tenant ordenado por fecha de creación.
SELECT tenant_id, created_at, status,
    SUM(CASE WHEN status = 'finalizado' THEN 1 ELSE 0 END)
        OVER (PARTITION BY tenant_id ORDER BY created_at) AS finalizados_acumulados
FROM tenanttemplates
ORDER BY tenant_id, created_at;

-- 51. Encuentra pares de organizaciones en la misma ciudad pero con diferentes tamaños de empresa.
SELECT a.name AS organizacion_1, b.name AS organizacion_2, c.name AS ciudad
FROM tenants a
JOIN tenants b ON a.city_id = b.city_id AND a.tenant_id < b.tenant_id
JOIN cities c ON c.city_id = a.city_id
WHERE a.tenant_size_id <> b.tenant_size_id;

-- 52. Obtiene las personas pertenecientes a cargos cuyo número de ocupantes supera el promedio en su organización.
WITH ocupacion AS (
    SELECT tenant_id, position_id, COUNT(*) AS total
    FROM persons
    GROUP BY tenant_id, position_id
),
promedio AS (
    SELECT tenant_id, AVG(total) AS promedio
    FROM ocupacion
    GROUP BY tenant_id
)
SELECT p.first_name, p.last_name, pos.description AS cargo, t.name AS organizacion
FROM persons p
JOIN positions pos ON pos.position_id = p.position_id
JOIN tenants t ON t.tenant_id = p.tenant_id
JOIN ocupacion o ON o.tenant_id = p.tenant_id AND o.position_id = p.position_id
JOIN promedio pr ON pr.tenant_id = p.tenant_id
WHERE o.total > pr.promedio;

-- 53. Obtiene organizaciones con más personas asociadas que el promedio general.
WITH personas_por_org AS (
    SELECT tenant_id, COUNT(*) AS total
    FROM persons
    GROUP BY tenant_id
)
SELECT t.name, p.total
FROM personas_por_org p
JOIN tenants t ON t.tenant_id = p.tenant_id
WHERE p.total > (SELECT AVG(total) FROM personas_por_org);

-- 54. Consolida la cantidad total de módulos, plantillas y personas asociadas a cada organización.
WITH modulos AS (
    SELECT tenant_id, COUNT(*) AS total_modulos FROM tenant_modules GROUP BY tenant_id
),
plantillas AS (
    SELECT tenant_id, COUNT(*) AS total_plantillas FROM tenanttemplates GROUP BY tenant_id
),
personas AS (
    SELECT tenant_id, COUNT(*) AS total_personas FROM persons GROUP BY tenant_id
)
SELECT t.tenant_id, t.name,
    COALESCE(m.total_modulos, 0) AS total_modulos,
    COALESCE(pl.total_plantillas, 0) AS total_plantillas,
    COALESCE(pe.total_personas, 0) AS total_personas
FROM tenants t
LEFT JOIN modulos m ON m.tenant_id = t.tenant_id
LEFT JOIN plantillas pl ON pl.tenant_id = t.tenant_id
LEFT JOIN personas pe ON pe.tenant_id = t.tenant_id;

-- 55. Encuentra las etapas PHVA que le faltan a cada organización.
SELECT t.tenant_id, t.name, ph.name AS etapa_faltante
FROM tenants t
CROSS JOIN phva_stages ph
WHERE NOT EXISTS (
    SELECT 1 FROM tenanttemplates tt
    WHERE tt.tenant_id = t.tenant_id AND tt.phva_stage_id = ph.phva_stage_id
);

-- 56. Muestra la fecha de última actualización de las plantillas para cada organización.
SELECT t.tenant_id, t.name, MAX(tt.updated_at) AS ultima_actualizacion
FROM tenants t
JOIN tenanttemplates tt ON tt.tenant_id = t.tenant_id
GROUP BY t.tenant_id, t.name;

-- 57. Une los pendientes tanto de SST como de PESV por organización.
SELECT tenant_id, tenant_name, pendientes, 'SST' AS sistema
FROM vm_template_sst_docs_summary
WHERE pendientes > 0
UNION ALL
SELECT tenant_id, tenant_name, pendientes, 'PESV' AS sistema
FROM vm_template_pesv_docs_summary
WHERE pendientes > 0;

-- 58. Calcula un resumen del estado de los documentos por cada tenant y su porcentaje de cumplimiento.
SELECT t.tenant_id, t.name,
    COUNT(*) AS total_documentos,
    COUNT(*) FILTER (WHERE tt.status = 'finalizado')  AS finalizados,
    COUNT(*) FILTER (WHERE tt.status = 'borrador')     AS en_borrador,
    COUNT(*) FILTER (WHERE tt.status = 'no_iniciado')  AS no_iniciados,
    COUNT(*) FILTER (WHERE tt.status = 'pendiente')    AS pendientes,
    ROUND(100.0 * COUNT(*) FILTER (WHERE tt.status = 'finalizado')
          / NULLIF(COUNT(*), 0), 2) AS porcentaje_cumplimiento
FROM tenants t
JOIN tenanttemplates tt ON tt.tenant_id = t.tenant_id
GROUP BY t.tenant_id, t.name;

-- 59. Identifica las organizaciones donde hay una diferencia mayor al 20% en cumplimiento entre SST y PESV.
SELECT s.tenant_id, s.tenant_name,
    s.porcentaje_cumplimiento AS porcentaje_sst,
    p.porcentaje_cumplimiento AS porcentaje_pesv,
    ABS(s.porcentaje_cumplimiento - p.porcentaje_cumplimiento) AS diferencia
FROM vm_template_sst_docs_summary s
JOIN vm_template_pesv_docs_summary p ON p.tenant_id = s.tenant_id
WHERE ABS(s.porcentaje_cumplimiento - p.porcentaje_cumplimiento) > 20;

-- 60. Crea una vista que resume totales de personas, módulos, plantillas y sistemas por organización.
CREATE VIEW vw_resumen_organizacion AS
SELECT t.tenant_id, t.name,
    COUNT(DISTINCT p.person_id)   AS total_personas,
    COUNT(DISTINCT tm.module_id)  AS total_modulos,
    COUNT(DISTINCT tt.template_id) AS total_plantillas,
    COUNT(DISTINCT tsy.system_id) AS total_sistemas
FROM tenants t
LEFT JOIN persons p ON p.tenant_id = t.tenant_id
LEFT JOIN tenant_modules tm ON tm.tenant_id = t.tenant_id
LEFT JOIN tenanttemplates tt ON tt.tenant_id = t.tenant_id
LEFT JOIN tenantsystems tsy ON tsy.tenant_id = t.tenant_id
GROUP BY t.tenant_id, t.name;


-- ==========================================
-- VISTAS Y VISTAS MATERIALIZADAS
-- ==========================================

-- 61. Crea una vista para listar a las personas de cada organización con su cargo.
CREATE VIEW vw_tenant_persons AS
SELECT t.tenant_id, t.name AS organizacion, p.person_id, p.first_name, p.last_name, pos.description AS cargo
FROM tenants t
JOIN persons p ON p.tenant_id = t.tenant_id
LEFT JOIN positions pos ON pos.position_id = p.position_id;

-- 62. Crea una vista con la ubicación completa (municipio, departamento, país) por cada organización.
CREATE VIEW vw_tenant_ubicacion AS
SELECT t.tenant_id, t.name AS organizacion, c.name AS municipio, s.name AS departamento, co.name AS pais
FROM tenants t
JOIN cities c ON c.city_id = t.city_id
JOIN states s ON s.state_id = c.state_id
JOIN countries co ON co.country_id = s.country_id;

-- 63. Crea una vista que muestra los módulos y sistemas asignados a las organizaciones.
CREATE VIEW vw_tenant_modules_sistema AS
SELECT t.tenant_id, t.name AS organizacion, m.title AS modulo, s.name AS sistema
FROM tenant_modules tm
JOIN tenants t ON t.tenant_id = tm.tenant_id
JOIN modules m ON m.module_id = tm.module_id
JOIN type_system_sst s ON s.system_id = m.system_id;

-- 64. Crea una vista que resume el número de plantillas por cada etapa PHVA de cada organización.
CREATE VIEW vw_plantillas_por_etapa AS
SELECT t.tenant_id, t.name AS organizacion, ph.name AS etapa_phva, COUNT(tt.template_id) AS total_plantillas
FROM tenanttemplates tt
JOIN tenants t ON t.tenant_id = tt.tenant_id
JOIN phva_stages ph ON ph.phva_stage_id = tt.phva_stage_id
GROUP BY t.tenant_id, t.name, ph.name;

-- 65. Crea una vista que muestra la cantidad de personas por cada cargo dentro de cada organización.
CREATE VIEW vw_personas_por_cargo AS
SELECT t.tenant_id, t.name AS organizacion, pos.description AS cargo, COUNT(p.person_id) AS total_personas
FROM tenants t
JOIN positions pos ON pos.tenant_id = t.tenant_id
LEFT JOIN persons p ON p.position_id = pos.position_id
GROUP BY t.tenant_id, t.name, pos.description;

-- 66. Crea una vista materializada para el resumen general del estado documental y porcentaje de cumplimiento.
CREATE MATERIALIZED VIEW vm_resumen_documental_general AS
SELECT t.tenant_id, t.name AS organizacion,
    COUNT(*) AS total_documentos,
    COUNT(*) FILTER (WHERE tt.status = 'finalizado') AS finalizados,
    COUNT(*) FILTER (WHERE tt.status = 'pendiente')  AS pendientes,
    ROUND(100.0 * COUNT(*) FILTER (WHERE tt.status = 'finalizado')
          / NULLIF(COUNT(*), 0), 2) AS porcentaje_cumplimiento
FROM tenants t
JOIN tenanttemplates tt ON tt.tenant_id = t.tenant_id
GROUP BY t.tenant_id, t.name;

-- 67. Refresca la vista materializada y luego la consulta.
REFRESH MATERIALIZED VIEW vm_resumen_documental_general;

SELECT * FROM vm_resumen_documental_general ORDER BY tenant_id;

-- 68. Crea índices sobre la vista materializada para optimizar las consultas.
CREATE INDEX idx_vm_resumen_tenant_id ON vm_resumen_documental_general (tenant_id);
CREATE INDEX idx_vm_resumen_porcentaje ON vm_resumen_documental_general (porcentaje_cumplimiento);


-- ==========================================
-- TRIGGERS
-- ==========================================

-- 69. Actualiza automáticamente la fecha de actualización (updated_at) de un tenant al ser modificado.
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

-- 70. Actualiza automáticamente la fecha de actualización (updated_at) de una persona al ser modificada.
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

-- 71. Impide registrar una persona en una organización inactiva.
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

-- 72. Impide asignar un módulo a un tenant si ya está previamente asignado.
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

-- 73. Impide asignar plantillas a una organización inactiva.
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

-- 74. Valida que una persona solo pueda ser asociada a un cargo que pertenezca a su misma organización.
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

-- 75. Actualiza automáticamente la fecha de actualización (updated_at) al modificarse una plantilla.
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

-- 76. Impide eliminar una organización si tiene personas asociadas a ella.
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

-- 77. Impide eliminar un sistema SST si existen organizaciones utilizándolo.
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

-- 78. Impide eliminar un módulo si está asignado a una o más organizaciones.
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

-- 79. Valida que el porcentaje de cumplimiento calculado permanezca dentro del rango de 0 a 100.
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

-- 80. Registra en una tabla de auditoría modificaciones sobre los datos principales de una organización.
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

-- 81. Registra en la tabla de auditoría cuando se modifica el estado de una organización.
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

-- 82. Registra la fecha y el usuario responsable cuando se modifique una plantilla (tenanttemplates).
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

-- 83. Marca como inactivos los bloqueos de edición vencidos (editing_locks) antes de insertar un nuevo bloqueo.
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
