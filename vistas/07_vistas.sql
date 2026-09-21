-- 1. vw_tenant_persons: consulta las organizaciones junto con sus personas y cargos asociados.
CREATE OR REPLACE VIEW vw_tenant_persons AS
SELECT t.name AS tenant_name, 
       p.first_name AS person_first_name, 
       p.last_name AS person_last_name, 
       pos.name AS position_name
FROM persons p
INNER JOIN positions pos ON p.position_id = pos.id
INNER JOIN tenants t ON pos.tenant_id = t.id;

-- 2. vw_tenant_geography: consolida información geográfica de las organizaciones.
CREATE OR REPLACE VIEW vw_tenant_geography AS
SELECT t.name AS tenant_name, 
       m.name AS municipality, 
       d.name AS department, 
       c.name AS country
FROM tenants t
LEFT JOIN municipalities m ON t.municipality_id = m.id
LEFT JOIN departments d ON m.department_id = d.id
LEFT JOIN countries c ON d.country_id = c.id;

-- 3. vw_tenant_modules_summary: muestra los módulos habilitados por organización y el sistema SST al que pertenecen.
CREATE OR REPLACE VIEW vw_tenant_modules_summary AS
SELECT t.name AS tenant_name, 
       m.title AS module_title, 
       sys.name AS system_name
FROM tenants t
INNER JOIN tenant_modules tm ON t.id = tm.tenant_id
INNER JOIN modules m ON tm.module_id = m.id
INNER JOIN type_system_sst sys ON m.type_system_sst_id = sys.id;

-- 4. vw_templates_by_stage: presenta la cantidad total de plantillas asociadas a cada organización y etapa PHVA.
CREATE OR REPLACE VIEW vw_templates_by_stage AS
SELECT t.name AS tenant_name, 
       phva.name AS stage_name, 
       COUNT(tt.id) AS total_templates
FROM tenants t
INNER JOIN tenant_templates tt ON t.id = tt.tenant_id
INNER JOIN templates temp ON tt.template_id = temp.id
INNER JOIN stages_phva phva ON temp.stage_phva_id = phva.id
GROUP BY t.id, t.name, phva.id, phva.name;

-- 5. vw_persons_by_position: consulta el total de personas por organización y cargo.
CREATE OR REPLACE VIEW vw_persons_by_position AS
SELECT t.name AS tenant_name, 
       pos.name AS position_name, 
       COUNT(p.id) AS total_persons
FROM tenants t
INNER JOIN positions pos ON t.id = pos.tenant_id
LEFT JOIN persons p ON pos.id = p.position_id
GROUP BY t.id, t.name, pos.id, pos.name;

-- 6. vm_template_sst_docs_summary: consolida resumen documental para SG-SST (type_system_sst_id = 1).
CREATE MATERIALIZED VIEW vm_template_sst_docs_summary AS
SELECT t.id AS tenant_id, 
       t.name AS tenant_name,
       COUNT(tt.id) AS total_documents,
       COUNT(tt.id) FILTER (WHERE tt.status = 'finalizado') AS finalizados,
       COUNT(tt.id) FILTER (WHERE tt.status = 'borrador') AS borrador,
       COUNT(tt.id) FILTER (WHERE tt.status = 'no_iniciado') AS no_iniciados,
       COUNT(tt.id) FILTER (WHERE tt.status = 'pendiente') AS pendientes,
       CASE 
           WHEN COUNT(tt.id) = 0 THEN 0 
           ELSE ROUND((COUNT(tt.id) FILTER (WHERE tt.status = 'finalizado') * 100.0) / COUNT(tt.id), 2) 
       END AS completion_percentage
FROM tenants t
LEFT JOIN (
    tenant_templates tt 
    INNER JOIN templates temp ON tt.template_id = temp.id 
    INNER JOIN modules m ON temp.module_id = m.id AND m.type_system_sst_id = 1
) ON t.id = tt.tenant_id
GROUP BY t.id, t.name;

-- 7. vm_template_pesv_docs_summary: consolida resumen documental para PESV (type_system_sst_id = 2).
CREATE MATERIALIZED VIEW vm_template_pesv_docs_summary AS
SELECT t.id AS tenant_id, 
       t.name AS tenant_name,
       COUNT(tt.id) AS total_documents,
       COUNT(tt.id) FILTER (WHERE tt.status = 'finalizado') AS finalizados,
       COUNT(tt.id) FILTER (WHERE tt.status = 'borrador') AS borrador,
       COUNT(tt.id) FILTER (WHERE tt.status = 'no_iniciado') AS no_iniciados,
       COUNT(tt.id) FILTER (WHERE tt.status = 'pendiente') AS pendientes,
       CASE 
           WHEN COUNT(tt.id) = 0 THEN 0 
           ELSE ROUND((COUNT(tt.id) FILTER (WHERE tt.status = 'finalizado') * 100.0) / COUNT(tt.id), 2) 
       END AS completion_percentage
FROM tenants t
LEFT JOIN (
    tenant_templates tt 
    INNER JOIN templates temp ON tt.template_id = temp.id 
    INNER JOIN modules m ON temp.module_id = m.id AND m.type_system_sst_id = 2
) ON t.id = tt.tenant_id
GROUP BY t.id, t.name;

-- Creación de índices para las vistas materializadas
CREATE INDEX idx_vm_template_sst_tenant_id ON vm_template_sst_docs_summary (tenant_id);
CREATE INDEX idx_vm_template_pesv_tenant_id ON vm_template_pesv_docs_summary (tenant_id);
