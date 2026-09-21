# Consultas SQL — SST/PESV

## Básicas

1.
```sql
SELECT * FROM tenants;
```

2.
```sql
SELECT name, contact_email, contact_phone FROM tenants;
```

3.
```sql
SELECT first_name, last_name, email FROM persons;
```

4.
```sql
SELECT * FROM persons WHERE status = 'activo';
```

5.
```sql
SELECT * FROM tenants WHERE name ILIKE '%palabra%';
```

6.
```sql
SELECT * FROM countries ORDER BY name;
```

7.
```sql
SELECT * FROM states WHERE country_id = 1;
```

8.
```sql
SELECT * FROM cities WHERE state_id = 1;
```

9.
```sql
SELECT * FROM positions ORDER BY description;
```

10.
```sql
SELECT * FROM persons WHERE tenant_id = 1;
```

11.
```sql
SELECT * FROM tenants WHERE status = 'activo';
```

12.
```sql
SELECT * FROM tenants WHERE created_at BETWEEN '2024-01-01' AND '2026-12-31';
```

13.
```sql
SELECT * FROM tenant_sizes;
```

14.
```sql
SELECT * FROM type_system_sst;
```

15.
```sql
SELECT title, description, display_order FROM modules ORDER BY display_order;
```

## Intermedias

1.
```sql
SELECT p.first_name, p.last_name, t.name AS organizacion
FROM persons p
JOIN tenants t ON t.tenant_id = p.tenant_id;
```

2.
```sql
SELECT p.first_name, p.last_name, pos.description AS cargo
FROM persons p
JOIN positions pos ON pos.position_id = p.position_id;
```

3.
```sql
SELECT t.name, ts.name AS tamano_empresa
FROM tenants t
JOIN tenant_sizes ts ON ts.tenant_size_id = t.tenant_size_id;
```

4.
```sql
SELECT t.name, c.name AS ciudad, s.name AS departamento, co.name AS pais
FROM tenants t
JOIN cities c ON c.city_id = t.city_id
JOIN states s ON s.state_id = c.state_id
JOIN countries co ON co.country_id = s.country_id;
```

5.
```sql
SELECT t.name, COUNT(p.person_id) AS total_personas
FROM tenants t
LEFT JOIN persons p ON p.tenant_id = t.tenant_id
GROUP BY t.tenant_id, t.name;
```

6.
```sql
SELECT t.name, COUNT(p.person_id) AS total_personas
FROM tenants t
JOIN persons p ON p.tenant_id = t.tenant_id
GROUP BY t.tenant_id, t.name
HAVING COUNT(p.person_id) > 3;
```

7.
```sql
SELECT t.name AS organizacion, m.title AS modulo
FROM tenant_modules tm
JOIN tenants t ON t.tenant_id = tm.tenant_id
JOIN modules m ON m.module_id = tm.module_id;
```

8.
```sql
SELECT t.name, COUNT(tm.module_id) AS total_modulos
FROM tenants t
JOIN tenant_modules tm ON tm.tenant_id = t.tenant_id
GROUP BY t.tenant_id, t.name;
```

9.
```sql
SELECT t.name AS organizacion, s.name AS sistema
FROM tenantsystems tsy
JOIN tenants t ON t.tenant_id = tsy.tenant_id
JOIN type_system_sst s ON s.system_id = tsy.system_id;
```

10.
```sql
SELECT m.title AS modulo, s.name AS sistema
FROM modules m
JOIN type_system_sst s ON s.system_id = m.system_id;
```

11.
```sql
SELECT f.name AS formato, m.title AS modulo
FROM formats_sst f
JOIN modules m ON m.module_id = f.module_id;
```

12.
```sql
SELECT m.title AS modulo, COUNT(f.format_id) AS total_formatos
FROM modules m
JOIN formats_sst f ON f.module_id = m.module_id
GROUP BY m.module_id, m.title;
```

13.
```sql
SELECT t.name AS organizacion, tt.template_id
FROM tenanttemplates tt
JOIN tenants t ON t.tenant_id = tt.tenant_id;
```

14.
```sql
SELECT t.name AS organizacion, s.name AS sistema, ph.name AS etapa_phva
FROM tenanttemplates tt
JOIN tenants t ON t.tenant_id = tt.tenant_id
JOIN type_system_sst s ON s.system_id = tt.system_id
JOIN phva_stages ph ON ph.phva_stage_id = tt.phva_stage_id;
```

15.
```sql
SELECT t.name, COUNT(tt.template_id) AS total_plantillas
FROM tenants t
JOIN tenanttemplates tt ON tt.tenant_id = t.tenant_id
GROUP BY t.tenant_id, t.name;
```

16.
```sql
SELECT t.*
FROM tenants t
LEFT JOIN persons p ON p.tenant_id = t.tenant_id
WHERE p.person_id IS NULL;
```

17.
```sql
SELECT m.*
FROM modules m
LEFT JOIN tenant_modules tm ON tm.module_id = m.module_id
WHERE tm.tenant_module_id IS NULL;
```

18.
```sql
SELECT ph.name AS etapa_phva, COUNT(tt.template_id) AS total_plantillas
FROM phva_stages ph
LEFT JOIN tenanttemplates tt ON tt.phva_stage_id = ph.phva_stage_id
GROUP BY ph.phva_stage_id, ph.name;
```

19.
```sql
SELECT c.name AS ciudad, COUNT(t.tenant_id) AS total_organizaciones
FROM cities c
JOIN tenants t ON t.city_id = c.city_id
GROUP BY c.city_id, c.name;
```

20.
```sql
SELECT t.name AS organizacion, pos.description AS cargo, COUNT(p.person_id) AS total_personas
FROM tenants t
JOIN positions pos ON pos.tenant_id = t.tenant_id
LEFT JOIN persons p ON p.position_id = pos.position_id
GROUP BY t.tenant_id, t.name, pos.position_id, pos.description;
```

## Avanzadas

1.
```sql
SELECT t.name, COUNT(p.person_id) AS total_personas
FROM tenants t
JOIN persons p ON p.tenant_id = t.tenant_id
GROUP BY t.tenant_id, t.name
ORDER BY total_personas DESC
LIMIT 1;
```

2.
```sql
WITH conteo AS (
    SELECT tenant_id, COUNT(*) AS total
    FROM persons
    GROUP BY tenant_id
)
SELECT t.name, c.total
FROM tenants t
JOIN conteo c ON c.tenant_id = t.tenant_id
WHERE c.total > (SELECT AVG(total) FROM conteo);
```

3.
```sql
SELECT t.name AS organizacion, m.system_id
FROM tenant_modules tm
JOIN tenants t ON t.tenant_id = tm.tenant_id
JOIN modules m ON m.module_id = tm.module_id
GROUP BY t.tenant_id, t.name, m.system_id
HAVING COUNT(DISTINCT tm.module_id) = (
    SELECT COUNT(*) FROM modules WHERE system_id = m.system_id
);
```

4.
```sql
SELECT DISTINCT t.tenant_id, t.name
FROM tenants t
JOIN tenant_modules tm ON tm.tenant_id = t.tenant_id
WHERE NOT EXISTS (
    SELECT 1 FROM tenanttemplates tt WHERE tt.tenant_id = t.tenant_id
);
```

5.
```sql
SELECT t.tenant_id, t.name
FROM tenants t
JOIN tenanttemplates tt ON tt.tenant_id = t.tenant_id
GROUP BY t.tenant_id, t.name
HAVING COUNT(DISTINCT tt.phva_stage_id) = (SELECT COUNT(*) FROM phva_stages);
```

6.
```sql
SELECT t.name, ph.name AS etapa, COUNT(*) AS total
FROM tenanttemplates tt
JOIN tenants t ON t.tenant_id = tt.tenant_id
JOIN phva_stages ph ON ph.phva_stage_id = tt.phva_stage_id
GROUP BY t.tenant_id, t.name, ph.name
ORDER BY t.name, ph.name;
```

7.
```sql
SELECT t.name,
    COUNT(*) FILTER (WHERE ph.name = 'Planear')   AS planear,
    COUNT(*) FILTER (WHERE ph.name = 'Hacer')      AS hacer,
    COUNT(*) FILTER (WHERE ph.name = 'Verificar')  AS verificar,
    COUNT(*) FILTER (WHERE ph.name = 'Actuar')     AS actuar
FROM tenanttemplates tt
JOIN tenants t ON t.tenant_id = tt.tenant_id
JOIN phva_stages ph ON ph.phva_stage_id = tt.phva_stage_id
GROUP BY t.tenant_id, t.name;
```

8.
```sql
SELECT t.name, ph.name AS etapa, COUNT(*) AS total,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY t.tenant_id), 2) AS porcentaje
FROM tenanttemplates tt
JOIN tenants t ON t.tenant_id = tt.tenant_id
JOIN phva_stages ph ON ph.phva_stage_id = tt.phva_stage_id
GROUP BY t.tenant_id, t.name, ph.name;
```

9.
```sql
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
```

10.
```sql
SELECT tenant_id, tenant_name, total_documentos, finalizados, porcentaje_cumplimiento, 'SST' AS sistema
FROM vm_template_sst_docs_summary
UNION ALL
SELECT tenant_id, tenant_name, total_documentos, finalizados, porcentaje_cumplimiento, 'PESV' AS sistema
FROM vm_template_pesv_docs_summary;
```

11.
```sql
WITH resumen AS (
    SELECT tenant_id, tenant_name, porcentaje_cumplimiento FROM vm_template_sst_docs_summary
    UNION ALL
    SELECT tenant_id, tenant_name, porcentaje_cumplimiento FROM vm_template_pesv_docs_summary
)
SELECT *
FROM resumen
WHERE porcentaje_cumplimiento < (SELECT AVG(porcentaje_cumplimiento) FROM resumen);
```

12.
```sql
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
```

13.
```sql
WITH resumen AS (
    SELECT tenant_id, tenant_name, porcentaje_cumplimiento FROM vm_template_sst_docs_summary
    UNION ALL
    SELECT tenant_id, tenant_name, porcentaje_cumplimiento FROM vm_template_pesv_docs_summary
)
SELECT tenant_id, tenant_name, porcentaje_cumplimiento,
    RANK() OVER (ORDER BY porcentaje_cumplimiento DESC) AS ranking
FROM resumen;
```

14.
```sql
WITH resumen AS (
    SELECT tenant_id, tenant_name, porcentaje_cumplimiento FROM vm_template_sst_docs_summary
    UNION ALL
    SELECT tenant_id, tenant_name, porcentaje_cumplimiento FROM vm_template_pesv_docs_summary
)
SELECT tenant_id, tenant_name, porcentaje_cumplimiento,
    porcentaje_cumplimiento - AVG(porcentaje_cumplimiento) OVER () AS diferencia_promedio
FROM resumen;
```

15.
```sql
SELECT tenant_id, created_at, status,
    SUM(CASE WHEN status = 'finalizado' THEN 1 ELSE 0 END)
        OVER (PARTITION BY tenant_id ORDER BY created_at) AS finalizados_acumulados
FROM tenanttemplates
ORDER BY tenant_id, created_at;
```

16.
```sql
SELECT a.name AS organizacion_1, b.name AS organizacion_2, c.name AS ciudad
FROM tenants a
JOIN tenants b ON a.city_id = b.city_id AND a.tenant_id < b.tenant_id
JOIN cities c ON c.city_id = a.city_id
WHERE a.tenant_size_id <> b.tenant_size_id;
```

17.
```sql
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
```

18.
```sql
WITH personas_por_org AS (
    SELECT tenant_id, COUNT(*) AS total
    FROM persons
    GROUP BY tenant_id
)
SELECT t.name, p.total
FROM personas_por_org p
JOIN tenants t ON t.tenant_id = p.tenant_id
WHERE p.total > (SELECT AVG(total) FROM personas_por_org);
```

19.
```sql
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
```

20.
```sql
SELECT t.tenant_id, t.name, ph.name AS etapa_faltante
FROM tenants t
CROSS JOIN phva_stages ph
WHERE NOT EXISTS (
    SELECT 1 FROM tenanttemplates tt
    WHERE tt.tenant_id = t.tenant_id AND tt.phva_stage_id = ph.phva_stage_id
);
```

21.
```sql
SELECT t.tenant_id, t.name, MAX(tt.updated_at) AS ultima_actualizacion
FROM tenants t
JOIN tenanttemplates tt ON tt.tenant_id = t.tenant_id
GROUP BY t.tenant_id, t.name;
```

22.
```sql
SELECT tenant_id, tenant_name, pendientes, 'SST' AS sistema
FROM vm_template_sst_docs_summary
WHERE pendientes > 0
UNION ALL
SELECT tenant_id, tenant_name, pendientes, 'PESV' AS sistema
FROM vm_template_pesv_docs_summary
WHERE pendientes > 0;
```

23.
```sql
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
```

24.
```sql
SELECT s.tenant_id, s.tenant_name,
    s.porcentaje_cumplimiento AS porcentaje_sst,
    p.porcentaje_cumplimiento AS porcentaje_pesv,
    ABS(s.porcentaje_cumplimiento - p.porcentaje_cumplimiento) AS diferencia
FROM vm_template_sst_docs_summary s
JOIN vm_template_pesv_docs_summary p ON p.tenant_id = s.tenant_id
WHERE ABS(s.porcentaje_cumplimiento - p.porcentaje_cumplimiento) > 20;
```

25.
```sql
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
```

## Vistas y vistas materializadas

1.
```sql
CREATE VIEW vw_tenant_persons AS
SELECT t.tenant_id, t.name AS organizacion, p.person_id, p.first_name, p.last_name, pos.description AS cargo
FROM tenants t
JOIN persons p ON p.tenant_id = t.tenant_id
LEFT JOIN positions pos ON pos.position_id = p.position_id;
```

2.
```sql
CREATE VIEW vw_tenant_ubicacion AS
SELECT t.tenant_id, t.name AS organizacion, c.name AS municipio, s.name AS departamento, co.name AS pais
FROM tenants t
JOIN cities c ON c.city_id = t.city_id
JOIN states s ON s.state_id = c.state_id
JOIN countries co ON co.country_id = s.country_id;
```

3.
```sql
CREATE VIEW vw_tenant_modules_sistema AS
SELECT t.tenant_id, t.name AS organizacion, m.title AS modulo, s.name AS sistema
FROM tenant_modules tm
JOIN tenants t ON t.tenant_id = tm.tenant_id
JOIN modules m ON m.module_id = tm.module_id
JOIN type_system_sst s ON s.system_id = m.system_id;
```

4.
```sql
CREATE VIEW vw_plantillas_por_etapa AS
SELECT t.tenant_id, t.name AS organizacion, ph.name AS etapa_phva, COUNT(tt.template_id) AS total_plantillas
FROM tenanttemplates tt
JOIN tenants t ON t.tenant_id = tt.tenant_id
JOIN phva_stages ph ON ph.phva_stage_id = tt.phva_stage_id
GROUP BY t.tenant_id, t.name, ph.name;
```

5.
```sql
CREATE VIEW vw_personas_por_cargo AS
SELECT t.tenant_id, t.name AS organizacion, pos.description AS cargo, COUNT(p.person_id) AS total_personas
FROM tenants t
JOIN positions pos ON pos.tenant_id = t.tenant_id
LEFT JOIN persons p ON p.position_id = pos.position_id
GROUP BY t.tenant_id, t.name, pos.description;
```

6.
```sql
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
```

7.
```sql
REFRESH MATERIALIZED VIEW vm_resumen_documental_general;

SELECT * FROM vm_resumen_documental_general ORDER BY tenant_id;
```

8.
```sql
CREATE INDEX idx_vm_resumen_tenant_id ON vm_resumen_documental_general (tenant_id);
CREATE INDEX idx_vm_resumen_porcentaje ON vm_resumen_documental_general (porcentaje_cumplimiento);
```

## Triggers

1.
```sql
CREATE OR REPLACE FUNCTION fn_tenants_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tenants_updated_at
BEFORE UPDATE ON tenants
FOR EACH ROW
EXECUTE FUNCTION fn_tenants_set_updated_at();
```

2.
```sql
CREATE OR REPLACE FUNCTION fn_persons_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_persons_updated_at
BEFORE UPDATE ON persons
FOR EACH ROW
EXECUTE FUNCTION fn_persons_set_updated_at();
```

3.
```sql
CREATE OR REPLACE FUNCTION fn_persons_check_tenant_active()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT status FROM tenants WHERE tenant_id = NEW.tenant_id) <> 'activo' THEN
        RAISE EXCEPTION 'No se puede registrar una persona en una organización inactiva';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_persons_check_tenant_active
BEFORE INSERT ON persons
FOR EACH ROW
EXECUTE FUNCTION fn_persons_check_tenant_active();
```

4.
```sql
CREATE OR REPLACE FUNCTION fn_tenant_modules_check_duplicado()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM tenant_modules
        WHERE tenant_id = NEW.tenant_id AND module_id = NEW.module_id
    ) THEN
        RAISE EXCEPTION 'El módulo ya se encuentra asignado a la organización';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tenant_modules_check_duplicado
BEFORE INSERT ON tenant_modules
FOR EACH ROW
EXECUTE FUNCTION fn_tenant_modules_check_duplicado();
```

5.
```sql
CREATE OR REPLACE FUNCTION fn_tenanttemplates_check_tenant_active()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT status FROM tenants WHERE tenant_id = NEW.tenant_id) <> 'activo' THEN
        RAISE EXCEPTION 'No se pueden asignar plantillas a una organización inactiva';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tenanttemplates_check_tenant_active
BEFORE INSERT ON tenanttemplates
FOR EACH ROW
EXECUTE FUNCTION fn_tenanttemplates_check_tenant_active();
```

6.
```sql
CREATE OR REPLACE FUNCTION fn_persons_check_position_tenant()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.position_id IS NOT NULL AND (
        SELECT tenant_id FROM positions WHERE position_id = NEW.position_id
    ) <> NEW.tenant_id THEN
        RAISE EXCEPTION 'El cargo no pertenece a la misma organización de la persona';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_persons_check_position_tenant
BEFORE INSERT OR UPDATE ON persons
FOR EACH ROW
EXECUTE FUNCTION fn_persons_check_position_tenant();
```

7.
```sql
CREATE OR REPLACE FUNCTION fn_tenanttemplates_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tenanttemplates_updated_at
BEFORE UPDATE ON tenanttemplates
FOR EACH ROW
EXECUTE FUNCTION fn_tenanttemplates_set_updated_at();
```

8.
```sql
CREATE OR REPLACE FUNCTION fn_tenants_check_no_persons()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM persons WHERE tenant_id = OLD.tenant_id) THEN
        RAISE EXCEPTION 'No se puede eliminar la organización porque tiene personas asociadas';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tenants_check_no_persons
BEFORE DELETE ON tenants
FOR EACH ROW
EXECUTE FUNCTION fn_tenants_check_no_persons();
```

9.
```sql
CREATE OR REPLACE FUNCTION fn_type_system_sst_check_no_tenants()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM tenantsystems WHERE system_id = OLD.system_id) THEN
        RAISE EXCEPTION 'No se puede eliminar el sistema SST porque está siendo utilizado por organizaciones';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_type_system_sst_check_no_tenants
BEFORE DELETE ON type_system_sst
FOR EACH ROW
EXECUTE FUNCTION fn_type_system_sst_check_no_tenants();
```

10.
```sql
CREATE OR REPLACE FUNCTION fn_modules_check_no_asignaciones()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM tenant_modules WHERE module_id = OLD.module_id) THEN
        RAISE EXCEPTION 'No se puede eliminar el módulo porque está asignado a una o más organizaciones';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_modules_check_no_asignaciones
BEFORE DELETE ON modules
FOR EACH ROW
EXECUTE FUNCTION fn_modules_check_no_asignaciones();
```

11.
```sql
CREATE TABLE tenant_compliance (
    tenant_id               INT PRIMARY KEY REFERENCES tenants(tenant_id),
    porcentaje_cumplimiento NUMERIC(5,2) NOT NULL,
    updated_at              TIMESTAMP NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION fn_tenant_compliance_check_rango()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.porcentaje_cumplimiento < 0 OR NEW.porcentaje_cumplimiento > 100 THEN
        RAISE EXCEPTION 'El porcentaje de cumplimiento debe estar entre 0 y 100';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tenant_compliance_check_rango
BEFORE INSERT OR UPDATE ON tenant_compliance
FOR EACH ROW
EXECUTE FUNCTION fn_tenant_compliance_check_rango();
```

12.
```sql
CREATE OR REPLACE FUNCTION fn_tenants_audit()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.name IS DISTINCT FROM OLD.name THEN
        INSERT INTO tenant_audit_log (tenant_id, field_name, old_value, new_value, changed_by)
        VALUES (NEW.tenant_id, 'name', OLD.name, NEW.name, current_user);
    END IF;
    IF NEW.nit IS DISTINCT FROM OLD.nit THEN
        INSERT INTO tenant_audit_log (tenant_id, field_name, old_value, new_value, changed_by)
        VALUES (NEW.tenant_id, 'nit', OLD.nit, NEW.nit, current_user);
    END IF;
    IF NEW.contact_email IS DISTINCT FROM OLD.contact_email THEN
        INSERT INTO tenant_audit_log (tenant_id, field_name, old_value, new_value, changed_by)
        VALUES (NEW.tenant_id, 'contact_email', OLD.contact_email, NEW.contact_email, current_user);
    END IF;
    IF NEW.contact_phone IS DISTINCT FROM OLD.contact_phone THEN
        INSERT INTO tenant_audit_log (tenant_id, field_name, old_value, new_value, changed_by)
        VALUES (NEW.tenant_id, 'contact_phone', OLD.contact_phone, NEW.contact_phone, current_user);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tenants_audit
AFTER UPDATE ON tenants
FOR EACH ROW
EXECUTE FUNCTION fn_tenants_audit();
```

13.
```sql
CREATE OR REPLACE FUNCTION fn_tenants_audit_status()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status IS DISTINCT FROM OLD.status THEN
        INSERT INTO tenant_audit_log (tenant_id, field_name, old_value, new_value, changed_by)
        VALUES (NEW.tenant_id, 'status', OLD.status, NEW.status, current_user);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tenants_audit_status
AFTER UPDATE ON tenants
FOR EACH ROW
EXECUTE FUNCTION fn_tenants_audit_status();
```

14.
```sql
CREATE OR REPLACE FUNCTION fn_tenanttemplates_registrar_modificacion()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := now();
    NEW.updated_by := current_user;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tenanttemplates_registrar_modificacion
BEFORE UPDATE ON tenanttemplates
FOR EACH ROW
EXECUTE FUNCTION fn_tenanttemplates_registrar_modificacion();
```

15.
```sql
CREATE OR REPLACE FUNCTION fn_editing_locks_limpiar_vencidos()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE editing_locks
    SET active = FALSE
    WHERE active = TRUE AND expires_at < now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_editing_locks_limpiar_vencidos
BEFORE INSERT ON editing_locks
FOR EACH ROW
EXECUTE FUNCTION fn_editing_locks_limpiar_vencidos();
```
