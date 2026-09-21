-- 1. Identificar la organización con mayor cantidad de personas registradas (nombre y total).
WITH TenantPersonCount AS (
    SELECT t.name AS tenant_name, COUNT(p.id) AS total_persons
    FROM tenants t
    LEFT JOIN positions pos ON t.id = pos.tenant_id
    LEFT JOIN persons p ON pos.id = p.position_id
    GROUP BY t.id, t.name
)
SELECT tenant_name, total_persons
FROM TenantPersonCount
ORDER BY total_persons DESC
LIMIT 1;

-- 2. Consultar las organizaciones cuya cantidad de personas sea superior al promedio general de personas por organización.
WITH TenantPersonCount AS (
    SELECT t.id, t.name AS tenant_name, COUNT(p.id) AS total_persons
    FROM tenants t
    LEFT JOIN positions pos ON t.id = pos.tenant_id
    LEFT JOIN persons p ON pos.id = p.position_id
    GROUP BY t.id, t.name
),
AvgPersons AS (
    SELECT AVG(total_persons) AS avg_persons FROM TenantPersonCount
)
SELECT tpc.tenant_name, tpc.total_persons
FROM TenantPersonCount tpc
CROSS JOIN AvgPersons ap
WHERE tpc.total_persons > ap.avg_persons;

-- 3. Identificar las organizaciones que tengan habilitados TODOS los módulos existentes para un sistema SST determinado (usa type_system_sst_id = 1 como ejemplo).
WITH TotalModulesSST1 AS (
    SELECT COUNT(id) AS total_modules FROM modules WHERE type_system_sst_id = 1
),
TenantModulesSST1 AS (
    SELECT tm.tenant_id, COUNT(tm.module_id) AS tenant_modules_count
    FROM tenant_modules tm
    INNER JOIN modules m ON tm.module_id = m.id
    WHERE m.type_system_sst_id = 1 AND tm.is_active = true
    GROUP BY tm.tenant_id
)
SELECT t.name AS tenant_name
FROM TenantModulesSST1 tms
INNER JOIN tenants t ON tms.tenant_id = t.id
CROSS JOIN TotalModulesSST1 tm1
WHERE tms.tenant_modules_count = tm1.total_modules;

-- 4. Determinar las organizaciones que tengan al menos un módulo configurado pero todavía no tengan plantillas asignadas.
SELECT t.name AS tenant_name
FROM tenants t
INNER JOIN tenant_modules tm ON t.id = tm.tenant_id
LEFT JOIN tenant_templates tt ON t.id = tt.tenant_id
WHERE tt.id IS NULL
GROUP BY t.id, t.name;

-- 5. Consultar las organizaciones que tengan plantillas asociadas a TODAS las etapas PHVA disponibles.
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
FROM TenantStages ts
INNER JOIN tenants t ON ts.tenant_id = t.id
CROSS JOIN TotalStages tos
WHERE ts.assigned_stages = tos.total_stages;

-- 6. Calcular la cantidad de plantillas asignadas a cada organización discriminadas por etapa PHVA.
SELECT t.name AS tenant_name, phva.name AS stage_name, COUNT(tt.id) AS total_templates
FROM tenants t
INNER JOIN tenant_templates tt ON t.id = tt.tenant_id
INNER JOIN templates temp ON tt.template_id = temp.id
INNER JOIN stages_phva phva ON temp.stage_phva_id = phva.id
GROUP BY t.id, t.name, phva.id, phva.name
ORDER BY t.name, phva."order";

-- 7. Construir una consulta que presente en columnas independientes (pivot) la cantidad de plantillas de Planear, Hacer, Verificar y Actuar para cada organización.
SELECT t.name AS tenant_name,
    COUNT(tt.id) FILTER (WHERE phva.name = 'Planear') AS planear,
    COUNT(tt.id) FILTER (WHERE phva.name = 'Hacer') AS hacer,
    COUNT(tt.id) FILTER (WHERE phva.name = 'Verificar') AS verificar,
    COUNT(tt.id) FILTER (WHERE phva.name = 'Actuar') AS actuar
FROM tenants t
LEFT JOIN tenant_templates tt ON t.id = tt.tenant_id
LEFT JOIN templates temp ON tt.template_id = temp.id
LEFT JOIN stages_phva phva ON temp.stage_phva_id = phva.id
GROUP BY t.id, t.name;

-- 8. Determinar el porcentaje que representa cada etapa PHVA sobre el total de plantillas asignadas a una organización.
WITH TenantStageCounts AS (
    SELECT t.id AS tenant_id, t.name AS tenant_name, phva.name AS stage_name, phva."order" AS stage_order, COUNT(tt.id) AS templates_per_stage
    FROM tenants t
    INNER JOIN tenant_templates tt ON t.id = tt.tenant_id
    INNER JOIN templates temp ON tt.template_id = temp.id
    INNER JOIN stages_phva phva ON temp.stage_phva_id = phva.id
    GROUP BY t.id, t.name, phva.id, phva.name, phva."order"
),
TenantTotalCounts AS (
    SELECT tenant_id, SUM(templates_per_stage) AS total_templates
    FROM TenantStageCounts
    GROUP BY tenant_id
)
SELECT tsc.tenant_name, tsc.stage_name,
       tsc.templates_per_stage,
       ROUND((tsc.templates_per_stage * 100.0) / ttc.total_templates, 2) AS percentage
FROM TenantStageCounts tsc
INNER JOIN TenantTotalCounts ttc ON tsc.tenant_id = ttc.tenant_id
ORDER BY tsc.tenant_name, tsc.stage_order;

-- 9. Identificar la etapa PHVA con mayor cantidad de plantillas asignadas dentro de cada organización.
WITH TenantStageCounts AS (
    SELECT t.id AS tenant_id, t.name AS tenant_name, phva.name AS stage_name, COUNT(tt.id) AS templates_per_stage
    FROM tenants t
    INNER JOIN tenant_templates tt ON t.id = tt.tenant_id
    INNER JOIN templates temp ON tt.template_id = temp.id
    INNER JOIN stages_phva phva ON temp.stage_phva_id = phva.id
    GROUP BY t.id, t.name, phva.id, phva.name
),
RankedStages AS (
    SELECT tenant_name, stage_name, templates_per_stage,
           RANK() OVER (PARTITION BY tenant_id ORDER BY templates_per_stage DESC) AS rnk
    FROM TenantStageCounts
)
SELECT tenant_name, stage_name, templates_per_stage
FROM RankedStages
WHERE rnk = 1;

-- 10. Calcular el porcentaje de documentos finalizados frente al total de documentos por organización, usando el campo status.
SELECT t.name AS tenant_name,
       COUNT(tt.id) AS total_documents,
       COUNT(tt.id) FILTER (WHERE tt.status = 'finalizado') AS finalizados,
       CASE
           WHEN COUNT(tt.id) = 0 THEN 0
           ELSE ROUND((COUNT(tt.id) FILTER (WHERE tt.status = 'finalizado') * 100.0) / COUNT(tt.id), 2)
       END AS completion_percentage
FROM tenants t
LEFT JOIN tenant_templates tt ON t.id = tt.tenant_id
GROUP BY t.id, t.name;

-- 11. Determinar las organizaciones cuyo porcentaje de cumplimiento documental esté por debajo del promedio general del sistema.
WITH TenantCompliance AS (
    SELECT t.id AS tenant_id, t.name AS tenant_name,
           CASE
               WHEN COUNT(tt.id) = 0 THEN 0
               ELSE (COUNT(tt.id) FILTER (WHERE tt.status = 'finalizado') * 100.0) / COUNT(tt.id)
           END AS completion_percentage
    FROM tenants t
    LEFT JOIN tenant_templates tt ON t.id = tt.tenant_id
    GROUP BY t.id, t.name
),
AvgCompliance AS (
    SELECT AVG(completion_percentage) AS avg_sys_compliance FROM TenantCompliance
)
SELECT tc.tenant_name, ROUND(tc.completion_percentage, 2) AS completion_percentage, ROUND(ac.avg_sys_compliance, 2) AS avg_sys_compliance
FROM TenantCompliance tc
CROSS JOIN AvgCompliance ac
WHERE tc.completion_percentage < ac.avg_sys_compliance;

-- 12. Clasificar las organizaciones según su porcentaje de cumplimiento en categorías bajo/medio/alto usando CASE.
WITH TenantCompliance AS (
    SELECT t.id AS tenant_id, t.name AS tenant_name,
           CASE
               WHEN COUNT(tt.id) = 0 THEN 0
               ELSE (COUNT(tt.id) FILTER (WHERE tt.status = 'finalizado') * 100.0) / COUNT(tt.id)
           END AS completion_percentage
    FROM tenants t
    LEFT JOIN tenant_templates tt ON t.id = tt.tenant_id
    GROUP BY t.id, t.name
)
SELECT tenant_name, ROUND(completion_percentage, 2) AS percentage,
       CASE
           WHEN completion_percentage < 40 THEN 'Bajo'
           WHEN completion_percentage >= 40 AND completion_percentage < 80 THEN 'Medio'
           ELSE 'Alto'
       END AS compliance_category
FROM TenantCompliance;

-- 13. Generar un ranking de organizaciones según su porcentaje de cumplimiento documental usando funciones de ventana (RANK).
WITH TenantCompliance AS (
    SELECT t.id AS tenant_id, t.name AS tenant_name,
           CASE
               WHEN COUNT(tt.id) = 0 THEN 0
               ELSE (COUNT(tt.id) FILTER (WHERE tt.status = 'finalizado') * 100.0) / COUNT(tt.id)
           END AS completion_percentage
    FROM tenants t
    LEFT JOIN tenant_templates tt ON t.id = tt.tenant_id
    GROUP BY t.id, t.name
)
SELECT tenant_name, ROUND(completion_percentage, 2) AS percentage,
       RANK() OVER (ORDER BY completion_percentage DESC) AS compliance_rank
FROM TenantCompliance;
