BEGIN;

-- ==============================================================================
-- 1. countries
-- ==============================================================================
CREATE TABLE countries (
    id SERIAL CONSTRAINT pk_countries PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code CHAR(3) NOT NULL CONSTRAINT uq_countries_code UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE countries IS 'Catálogo de países.';
COMMENT ON COLUMN countries.code IS 'Código ISO de 3 caracteres del país.';

-- ==============================================================================
-- 2. departments
-- ==============================================================================
CREATE TABLE departments (
    id SERIAL CONSTRAINT pk_departments PRIMARY KEY,
    country_id INT NOT NULL CONSTRAINT fk_departments_country_id REFERENCES countries(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE departments IS 'Catálogo de departamentos/estados, dependientes de un país.';

-- ==============================================================================
-- 3. municipalities
-- ==============================================================================
CREATE TABLE municipalities (
    id SERIAL CONSTRAINT pk_municipalities PRIMARY KEY,
    department_id INT NOT NULL CONSTRAINT fk_municipalities_department_id REFERENCES departments(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE municipalities IS 'Catálogo de municipios/ciudades, dependientes de un departamento.';

-- ==============================================================================
-- 4. tenant_sizes
-- ==============================================================================
CREATE TABLE tenant_sizes (
    id SERIAL CONSTRAINT pk_tenant_sizes PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE tenant_sizes IS 'Catálogo de tamaños de empresa (ej. Micro, Pequeña, Mediana, Grande).';

-- ==============================================================================
-- 5. type_system_sst
-- ==============================================================================
CREATE TABLE type_system_sst (
    id SERIAL CONSTRAINT pk_type_system_sst PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE type_system_sst IS 'Tipos de sistema SST o estándares a aplicar.';

-- ==============================================================================
-- 6. stages_phva
-- ==============================================================================
CREATE TABLE stages_phva (
    id SERIAL CONSTRAINT pk_stages_phva PRIMARY KEY,
    name VARCHAR(50) NOT NULL CONSTRAINT ck_stages_phva_name CHECK (name IN ('Planear','Hacer','Verificar','Actuar')),
    "order" INT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE stages_phva IS 'Fases del ciclo PHVA (Planear, Hacer, Verificar, Actuar).';
COMMENT ON COLUMN stages_phva."order" IS 'Orden lógico de ejecución de la fase.';

-- ==============================================================================
-- 7. positions
-- ==============================================================================
CREATE TABLE positions (
    id SERIAL CONSTRAINT pk_positions PRIMARY KEY,
    tenant_id INT NOT NULL CONSTRAINT fk_positions_tenant_id REFERENCES tenants(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE positions IS 'Catálogo de cargos o roles dentro de un tenant.';

-- ==============================================================================
-- 8. modules
-- ==============================================================================
CREATE TABLE modules (
    id SERIAL CONSTRAINT pk_modules PRIMARY KEY,
    type_system_sst_id INT NOT NULL CONSTRAINT fk_modules_type_system_sst_id REFERENCES type_system_sst(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    "order" INT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE modules IS 'Módulos que componen un tipo de sistema SST.';

-- ==============================================================================
-- 9. tenants
-- ==============================================================================
CREATE TABLE tenants (
    id SERIAL CONSTRAINT pk_tenants PRIMARY KEY,
    tenant_size_id INT CONSTRAINT fk_tenants_tenant_size_id REFERENCES tenant_sizes(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    municipality_id INT CONSTRAINT fk_tenants_municipality_id REFERENCES municipalities(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    name VARCHAR(150) NOT NULL,
    nit VARCHAR(20) NOT NULL CONSTRAINT uq_tenants_nit UNIQUE,
    contact_email VARCHAR(150),
    contact_phone VARCHAR(30),
    address TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE tenants IS 'Empresas clientes u organizaciones (Tenants) en el sistema.';
COMMENT ON COLUMN tenants.nit IS 'Número de Identificación Tributaria, debe ser único.';

-- ==============================================================================
-- 10. persons
-- ==============================================================================
CREATE TABLE persons (
    id SERIAL CONSTRAINT pk_persons PRIMARY KEY,
    position_id INT NOT NULL CONSTRAINT fk_persons_position_id REFERENCES positions(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    first_name VARCHAR(80) NOT NULL,
    last_name VARCHAR(80) NOT NULL,
    email VARCHAR(150) NOT NULL,
    document_number VARCHAR(30),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE persons IS 'Personas o usuarios asociados a un tenant.';
COMMENT ON COLUMN persons.email IS 'Correo electrónico del usuario, único por cada tenant.';

-- ==============================================================================
-- 11. tenantsystems
-- ==============================================================================
CREATE TABLE tenantsystems (
    id SERIAL CONSTRAINT pk_tenantsystems PRIMARY KEY,
    tenant_id INT NOT NULL CONSTRAINT fk_tenantsystems_tenant_id REFERENCES tenants(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    type_system_sst_id INT NOT NULL CONSTRAINT fk_tenantsystems_type_system_sst_id REFERENCES type_system_sst(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_tenantsystems_tenant_type UNIQUE(tenant_id, type_system_sst_id)
);

COMMENT ON TABLE tenantsystems IS 'Asociación de sistemas SST activos por cada tenant.';

-- ==============================================================================
-- 12. tenant_modules
-- ==============================================================================
CREATE TABLE tenant_modules (
    id SERIAL CONSTRAINT pk_tenant_modules PRIMARY KEY,
    tenant_id INT NOT NULL CONSTRAINT fk_tenant_modules_tenant_id REFERENCES tenants(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    module_id INT NOT NULL CONSTRAINT fk_tenant_modules_module_id REFERENCES modules(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_tenant_modules_tenant_module UNIQUE(tenant_id, module_id)
);

COMMENT ON TABLE tenant_modules IS 'Módulos específicos habilitados para cada tenant.';

-- ==============================================================================
-- 13. templates
-- ==============================================================================
CREATE TABLE templates (
    id SERIAL CONSTRAINT pk_templates PRIMARY KEY,
    stage_phva_id INT CONSTRAINT fk_templates_stage_phva_id REFERENCES stages_phva(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    module_id INT NOT NULL CONSTRAINT fk_templates_module_id REFERENCES modules(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE templates IS 'Plantillas base del sistema SST asociadas a ciclos PHVA y Módulos.';

-- ==============================================================================
-- 14. formats_sst
-- ==============================================================================
CREATE TABLE formats_sst (
    id SERIAL CONSTRAINT pk_formats_sst PRIMARY KEY,
    module_id INT NOT NULL CONSTRAINT fk_formats_sst_module_id REFERENCES modules(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE formats_sst IS 'Formatos o documentos específicos de un módulo SST.';

-- ==============================================================================
-- 15. tenant_templates
-- ==============================================================================
CREATE TABLE tenant_templates (
    id SERIAL CONSTRAINT pk_tenant_templates PRIMARY KEY,
    tenant_id INT NOT NULL CONSTRAINT fk_tenant_templates_tenant_id REFERENCES tenants(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    template_id INT NOT NULL CONSTRAINT fk_tenant_templates_template_id REFERENCES templates(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    format_sst_id INT CONSTRAINT fk_tenant_templates_format_sst_id REFERENCES formats_sst(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'no_iniciado' CONSTRAINT ck_tenant_templates_status CHECK (status IN ('no_iniciado','borrador','finalizado','pendiente')),
    completed_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_tenant_templates_tenant_template UNIQUE(tenant_id, template_id)
);

COMMENT ON TABLE tenant_templates IS 'Instancias de plantillas gestionadas por el tenant.';
COMMENT ON COLUMN tenant_templates.status IS 'Estado actual del avance sobre la plantilla.';

-- ==============================================================================
-- 16. evaluations
-- ==============================================================================
CREATE TABLE evaluations (
    id SERIAL CONSTRAINT pk_evaluations PRIMARY KEY,
    tenant_id INT NOT NULL CONSTRAINT fk_evaluations_tenant_id REFERENCES tenants(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    template_id INT CONSTRAINT fk_evaluations_template_id REFERENCES templates(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    score NUMERIC(5,2) CONSTRAINT ck_evaluations_score CHECK (score >= 0 AND score <= 100),
    evaluated_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE evaluations IS 'Evaluaciones o calificaciones que ha obtenido el tenant.';
COMMENT ON COLUMN evaluations.score IS 'Puntuación de la evaluación entre 0 y 100.';

-- ==============================================================================
-- 17. editing_locks
-- ==============================================================================
CREATE TABLE editing_locks (
    id SERIAL CONSTRAINT pk_editing_locks PRIMARY KEY,
    resource_type VARCHAR(60) NOT NULL,
    resource_id INT NOT NULL,
    locked_by INT NOT NULL CONSTRAINT fk_editing_locks_locked_by REFERENCES persons(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    locked_at TIMESTAMP NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE editing_locks IS 'Bloqueos de concurrencia para la edición de recursos.';
COMMENT ON COLUMN editing_locks.locked_by IS 'Usuario que retiene el bloqueo.';

-- ==============================================================================
-- 18. audit_tenants
-- ==============================================================================
CREATE TABLE audit_tenants (
    id SERIAL CONSTRAINT pk_audit_tenants PRIMARY KEY,
    tenant_id INT NOT NULL,
    field_changed VARCHAR(80),
    old_value TEXT,
    new_value TEXT,
    changed_by VARCHAR(80),
    changed_at TIMESTAMP NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
    -- Nótese que aquí no incluimos `updated_at` según las reglas
);

COMMENT ON TABLE audit_tenants IS 'Auditoría histórica de cambios en tenants, sobrevive la eliminación del tenant.';
COMMENT ON COLUMN audit_tenants.tenant_id IS 'ID del tenant, no ligado con FK para prevenir borrado en cascada.';

COMMIT;

/*
==============================================================================
RESUMEN DE TABLAS CREADAS (18):
==============================================================================
1.  countries
2.  departments
3.  municipalities
4.  tenant_sizes
5.  type_system_sst
6.  stages_phva
7.  positions
8.  modules
9.  tenants
10. persons
11. tenantsystems
12. tenant_modules
13. templates
14. formats_sst
15. tenant_templates
16. evaluations
17. editing_locks
18. audit_tenants
==============================================================================
*/
