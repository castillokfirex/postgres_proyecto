-- 1. Mostrar para cada organización su porcentaje de cumplimiento y la diferencia respecto al promedio general de cumplimiento.
WITH TenantCompliance AS (
    SELECT t.id AS tenant_id, t.name AS tenant_name,
           CASE WHEN COUNT(tt.id) = 0 THEN 0 ELSE (COUNT(tt.id) FILTER (WHERE tt.status = 'finalizado') * 100.0) / COUNT(tt.id) END AS compliance
    FROM tenants t
    LEFT JOIN tenant_templates tt ON t.id = tt.tenant_id
    GROUP BY t.id, t.name
),
AvgCompliance AS (
    SELECT AVG(compliance) AS avg_sys_compliance FROM TenantCompliance
)
SELECT tc.tenant_name, ROUND(tc.compliance, 2) AS percentage,
       ROUND(tc.compliance - ac.avg_sys_compliance, 2) AS diff_vs_avg
FROM TenantCompliance tc
CROSS JOIN AvgCompliance ac;

-- 2. Determinar la cantidad acumulada de documentos finalizados por organización usando una función de ventana (SUM OVER con ORDER BY).
SELECT t.name AS tenant_name, tt.completed_at,
       SUM(1) OVER (PARTITION BY tt.tenant_id ORDER BY tt.completed_at ASC NULLS LAST) AS cumulative_completed
FROM tenants t
INNER JOIN tenant_templates tt ON t.id = tt.tenant_id
WHERE tt.status = 'finalizado'
ORDER BY t.name, tt.completed_at;

-- 3. Identificar las organizaciones que compartan el mismo municipio pero tengan diferente tamaño empresarial.
SELECT DISTINCT t1.name AS tenant_1, t2.name AS tenant_2, m.name AS municipality
FROM tenants t1
INNER JOIN tenants t2 ON t1.municipality_id = t2.municipality_id AND t1.id < t2.id
INNER JOIN municipalities m ON t1.municipality_id = m.id
WHERE t1.tenant_size_id != t2.tenant_size_id;

-- 4. Encontrar las personas cuyo cargo sea utilizado por más personas que el promedio de ocupación de los cargos dentro de su organización.
WITH PositionCounts AS (
    SELECT pos.tenant_id, p.position_id, COUNT(p.id) AS position_count
    FROM persons p
    INNER JOIN positions pos ON p.position_id = pos.id
    GROUP BY pos.tenant_id, p.position_id
),
AvgPositionPerTenant AS (
    SELECT tenant_id, AVG(position_count) AS avg_position_count
    FROM PositionCounts
    GROUP BY tenant_id
)
SELECT p.first_name, p.last_name, t.name AS tenant_name, pos.name AS position_name
FROM persons p
INNER JOIN positions pos ON p.position_id = pos.id
INNER JOIN PositionCounts pc ON pos.tenant_id = pc.tenant_id AND p.position_id = pc.position_id
INNER JOIN AvgPositionPerTenant apt ON pos.tenant_id = apt.tenant_id
INNER JOIN tenants t ON pos.tenant_id = t.id
WHERE pc.position_count > apt.avg_position_count;

-- 5. Utilizar un CTE para calcular la cantidad de personas por organización y luego seleccionar únicamente las que superen el promedio.
WITH TenantPersons AS (
    SELECT t.id, t.name AS tenant_name, COUNT(p.id) AS total_persons
    FROM tenants t
    LEFT JOIN positions pos ON t.id = pos.tenant_id
    LEFT JOIN persons p ON pos.id = p.position_id
    GROUP BY t.id, t.name
),
AvgPersons AS (
    SELECT AVG(total_persons) AS avg_p FROM TenantPersons
)
SELECT tp.tenant_name, tp.total_persons
FROM TenantPersons tp
CROSS JOIN AvgPersons ap
WHERE tp.total_persons > ap.avg_p;

-- 6. Utilizar un CTE para consolidar la cantidad de módulos, plantillas y personas correspondientes a cada organización.
WITH Consolidado AS (
    SELECT t.id, t.name AS tenant_name,
           (SELECT COUNT(*) FROM tenant_modules tm WHERE tm.tenant_id = t.id) AS total_modules,
           (SELECT COUNT(*) FROM tenant_templates tt WHERE tt.tenant_id = t.id) AS total_templates,
           (SELECT COUNT(*) FROM persons p INNER JOIN positions pos ON p.position_id = pos.id WHERE pos.tenant_id = t.id) AS total_persons
    FROM tenants t
)
SELECT tenant_name, total_modules, total_templates, total_persons FROM Consolidado;

-- 7. Determinar las organizaciones que NO tengan configurada alguna etapa PHVA requerida dentro de sus plantillas (interpreta: que les falte al menos una de las 4 etapas).
WITH TotalStages AS (
    SELECT COUNT(id) AS total_stages FROM stages_phva
),
TenantStages AS (
    SELECT tt.tenant_id, COUNT(DISTINCT temp.stage_phva_id) AS assigned_stages
    FROM tenant_templates tt
    INNER JOIN templates temp ON tt.template_id = temp.id
    GROUP BY tt.tenant_id
)
SELECT t.name AS tenant_name
FROM tenants t
LEFT JOIN TenantStages ts ON t.id = ts.tenant_id
CROSS JOIN TotalStages tos
WHERE COALESCE(ts.assigned_stages, 0) < tos.total_stages;

-- 8. Consultar la última fecha de actualización registrada para cada organización considerando sus plantillas asociadas (usa MAX(updated_at) de tenant_templates).
SELECT t.name AS tenant_name, MAX(tt.updated_at) AS last_template_update
FROM tenants t
LEFT JOIN tenant_templates tt ON t.id = tt.tenant_id
GROUP BY t.id, t.name;

-- 9. Determinar cuáles organizaciones presentan registros documentales pendientes (status = 'pendiente' o 'no_iniciado') en tenant_templates.
SELECT DISTINCT t.name AS tenant_name
FROM tenants t
INNER JOIN tenant_templates tt ON t.id = tt.tenant_id
WHERE tt.status IN ('pendiente', 'no_iniciado');

-- 10. Generar un informe consolidado por organización con: total de documentos, finalizados, en borrador, no iniciados, pendientes y porcentaje de cumplimiento.
SELECT t.name AS tenant_name,
       COUNT(tt.id) AS total_documents,
       COUNT(tt.id) FILTER (WHERE tt.status = 'finalizado') AS finalizados,
       COUNT(tt.id) FILTER (WHERE tt.status = 'borrador') AS borrador,
       COUNT(tt.id) FILTER (WHERE tt.status = 'no_iniciado') AS no_iniciados,
       COUNT(tt.id) FILTER (WHERE tt.status = 'pendiente') AS pendientes,
       CASE WHEN COUNT(tt.id) = 0 THEN 0 ELSE ROUND((COUNT(tt.id) FILTER (WHERE tt.status = 'finalizado') * 100.0) / COUNT(tt.id), 2) END AS completion_percentage
FROM tenants t
LEFT JOIN tenant_templates tt ON t.id = tt.tenant_id
GROUP BY t.id, t.name;

-- 11. Comparar el porcentaje de cumplimiento SST (type_system_sst_id = 1) vs PESV (type_system_sst_id = 2) de cada organización, identificando diferencias superiores a 20 puntos porcentuales.
WITH TenantSysCompliance AS (
    SELECT t.id AS tenant_id, t.name AS tenant_name, m.type_system_sst_id,
           CASE WHEN COUNT(tt.id) = 0 THEN 0 ELSE (COUNT(tt.id) FILTER (WHERE tt.status = 'finalizado') * 100.0) / COUNT(tt.id) END AS compliance
    FROM tenants t
    INNER JOIN tenant_templates tt ON t.id = tt.tenant_id
    INNER JOIN templates temp ON tt.template_id = temp.id
    INNER JOIN modules m ON temp.module_id = m.id
    GROUP BY t.id, t.name, m.type_system_sst_id
),
PivotedCompliance AS (
    SELECT tenant_id, tenant_name,
           MAX(compliance) FILTER (WHERE type_system_sst_id = 1) AS sgsst_compliance,
           MAX(compliance) FILTER (WHERE type_system_sst_id = 2) AS pesv_compliance
    FROM TenantSysCompliance
    GROUP BY tenant_id, tenant_name
)
SELECT tenant_name,
       ROUND(COALESCE(sgsst_compliance, 0), 2) AS sgsst_compliance,
       ROUND(COALESCE(pesv_compliance, 0), 2) AS pesv_compliance,
       ROUND(ABS(COALESCE(sgsst_compliance, 0) - COALESCE(pesv_compliance, 0)), 2) AS diff
FROM PivotedCompliance
WHERE ABS(COALESCE(sgsst_compliance, 0) - COALESCE(pesv_compliance, 0)) > 20;

-- 12. Construir una consulta que consolide la cantidad de personas, módulos, plantillas y sistemas habilitados para cada organización.
SELECT t.name AS tenant_name,
       (SELECT COUNT(*) FROM persons p INNER JOIN positions pos ON p.position_id = pos.id WHERE pos.tenant_id = t.id) AS total_persons,
       (SELECT COUNT(*) FROM tenant_modules tm WHERE tm.tenant_id = t.id) AS total_modules,
       (SELECT COUNT(*) FROM tenant_templates tt WHERE tt.tenant_id = t.id) AS total_templates,
       (SELECT COUNT(*) FROM tenantsystems ts WHERE ts.tenant_id = t.id) AS total_systems
FROM tenants t;
