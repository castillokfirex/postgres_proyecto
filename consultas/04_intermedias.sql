-- 1. Consultar todas las personas mostrando su nombre completo y el nombre de la organización a la que pertenecen.
SELECT p.first_name, p.last_name, t.name AS tenant_name
FROM persons p
INNER JOIN positions pos ON p.position_id = pos.id
INNER JOIN tenants t ON pos.tenant_id = t.id;

-- 2. Consultar cada persona junto con el cargo que desempeña.
SELECT p.first_name, p.last_name, pos.name AS position_name
FROM persons p
INNER JOIN positions pos ON p.position_id = pos.id;

-- 3. Mostrar cada organización junto con el tamaño de empresa que tiene asignado.
SELECT t.name AS tenant_name, ts.name AS size_name
FROM tenants t
INNER JOIN tenant_sizes ts ON t.tenant_size_id = ts.id;

-- 4. Consultar cada organización mostrando ciudad, departamento y país donde está registrada.
SELECT t.name AS tenant_name, m.name AS municipality, d.name AS department, c.name AS country
FROM tenants t
INNER JOIN municipalities m ON t.municipality_id = m.id
INNER JOIN departments d ON m.department_id = d.id
INNER JOIN countries c ON d.country_id = c.id;

-- 5. Determinar cuántas personas están registradas en cada organización.
SELECT t.name AS tenant_name, COUNT(p.id) AS total_persons
FROM tenants t
LEFT JOIN positions pos ON t.id = pos.tenant_id
LEFT JOIN persons p ON pos.id = p.position_id
GROUP BY t.id, t.name;

-- 6. Identificar las organizaciones con más de 3 personas registradas.
SELECT t.name AS tenant_name, COUNT(p.id) AS total_persons
FROM tenants t
INNER JOIN positions pos ON t.id = pos.tenant_id
INNER JOIN persons p ON pos.id = p.position_id
GROUP BY t.id, t.name
HAVING COUNT(p.id) > 3;

-- 7. Consultar los módulos habilitados para cada organización usando tenant_modules.
SELECT t.name AS tenant_name, m.title AS module_title
FROM tenant_modules tm
INNER JOIN tenants t ON tm.tenant_id = t.id
INNER JOIN modules m ON tm.module_id = m.id;

-- 8. Determinar cuántos módulos tiene habilitados cada organización.
SELECT t.name AS tenant_name, COUNT(tm.module_id) AS total_modules
FROM tenants t
LEFT JOIN tenant_modules tm ON t.id = tm.tenant_id
GROUP BY t.id, t.name;

-- 9. Consultar los sistemas SST habilitados por organización usando tenantsystems y type_system_sst.
SELECT t.name AS tenant_name, sys.name AS system_name
FROM tenantsystems ts
INNER JOIN tenants t ON ts.tenant_id = t.id
INNER JOIN type_system_sst sys ON ts.type_system_sst_id = sys.id;

-- 10. Mostrar los módulos existentes junto con el sistema SST al que pertenecen.
SELECT m.title AS module_title, sys.name AS system_name
FROM modules m
INNER JOIN type_system_sst sys ON m.type_system_sst_id = sys.id;

-- 11. Consultar los formatos de formats_sst mostrando el módulo al que pertenece cada uno.
SELECT f.name AS format_name, m.title AS module_title
FROM formats_sst f
INNER JOIN modules m ON f.module_id = m.id;

-- 12. Determinar cuántos formatos están asociados a cada módulo.
SELECT m.title AS module_title, COUNT(f.id) AS total_formats
FROM modules m
LEFT JOIN formats_sst f ON m.id = f.module_id
GROUP BY m.id, m.title;

-- 13. Consultar las plantillas asignadas a cada organización mediante tenant_templates.
SELECT t.name AS tenant_name, temp.name AS template_name
FROM tenant_templates tt
INNER JOIN tenants t ON tt.tenant_id = t.id
INNER JOIN templates temp ON tt.template_id = temp.id;

-- 14. Mostrar cada plantilla asignada indicando organización, sistema SST y etapa PHVA relacionada.
SELECT t.name AS tenant_name, temp.name AS template_name, sys.name AS system_name, phva.name AS stage_name
FROM tenant_templates tt
INNER JOIN tenants t ON tt.tenant_id = t.id
INNER JOIN templates temp ON tt.template_id = temp.id
INNER JOIN modules m ON temp.module_id = m.id
INNER JOIN type_system_sst sys ON m.type_system_sst_id = sys.id
INNER JOIN stages_phva phva ON temp.stage_phva_id = phva.id;

-- 15. Determinar cuántas plantillas tiene asignadas cada organización.
SELECT t.name AS tenant_name, COUNT(tt.id) AS total_templates
FROM tenants t
LEFT JOIN tenant_templates tt ON t.id = tt.tenant_id
GROUP BY t.id, t.name;

-- 16. Consultar las organizaciones que actualmente NO tengan personas registradas (usa LEFT JOIN).
SELECT t.name AS tenant_name
FROM tenants t
LEFT JOIN positions pos ON t.id = pos.tenant_id
LEFT JOIN persons p ON pos.id = p.position_id
WHERE p.id IS NULL;

-- 17. Identificar los módulos que todavía no han sido asignados a ninguna organización.
SELECT m.title AS module_title
FROM modules m
LEFT JOIN tenant_modules tm ON m.id = tm.module_id
WHERE tm.id IS NULL;

-- 18. Consultar las etapas PHVA mostrando cuántas plantillas base (templates) están asociadas a cada una.
SELECT phva.name AS stage_name, COUNT(temp.id) AS total_templates
FROM stages_phva phva
LEFT JOIN templates temp ON phva.id = temp.stage_phva_id
GROUP BY phva.id, phva.name;

-- 19. Determinar cuántas organizaciones están registradas en cada municipio.
SELECT m.name AS municipality, COUNT(t.id) AS total_tenants
FROM municipalities m
LEFT JOIN tenants t ON m.id = t.municipality_id
GROUP BY m.id, m.name;

-- 20. Consultar los cargos existentes en cada organización y cuántas personas ocupan cada cargo.
SELECT t.name AS tenant_name, pos.name AS position_name, COUNT(p.id) AS total_persons
FROM tenants t
INNER JOIN positions pos ON t.id = pos.tenant_id
LEFT JOIN persons p ON pos.id = p.position_id
GROUP BY t.id, t.name, pos.id, pos.name;
