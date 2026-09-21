CREATE TABLE countries (
    country_id   SERIAL PRIMARY KEY,
    name         VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE states (
    state_id     SERIAL PRIMARY KEY,
    country_id   INT NOT NULL REFERENCES countries(country_id),
    name         VARCHAR(100) NOT NULL,
    UNIQUE (country_id, name)
);

CREATE TABLE cities (
    city_id      SERIAL PRIMARY KEY,
    state_id     INT NOT NULL REFERENCES states(state_id),
    name         VARCHAR(100) NOT NULL,
    UNIQUE (state_id, name)
);

-- =========================================================
-- Parametrización de empresas
-- =========================================================
CREATE TABLE tenant_sizes (
    tenant_size_id SERIAL PRIMARY KEY,
    name           VARCHAR(50) NOT NULL UNIQUE,
    description    TEXT
);

-- =========================================================
-- Empresas (tenants)
-- =========================================================
CREATE TABLE tenants (
    tenant_id      SERIAL PRIMARY KEY,
    name           VARCHAR(150) NOT NULL,
    nit            VARCHAR(30) NOT NULL UNIQUE,
    contact_email  VARCHAR(150),
    contact_phone  VARCHAR(30),
    tenant_size_id INT REFERENCES tenant_sizes(tenant_size_id),
    city_id        INT REFERENCES cities(city_id),
    status         VARCHAR(20) NOT NULL DEFAULT 'activo'
                     CHECK (status IN ('activo','inactivo')),
    created_at     TIMESTAMP NOT NULL DEFAULT now(),
    updated_at     TIMESTAMP NOT NULL DEFAULT now()
);

-- =========================================================
-- Cargos (por organización)
-- =========================================================
CREATE TABLE positions (
    position_id  SERIAL PRIMARY KEY,
    tenant_id    INT NOT NULL REFERENCES tenants(tenant_id),
    description  VARCHAR(150) NOT NULL,
    UNIQUE (tenant_id, description)
);

-- =========================================================
-- Personas
-- =========================================================
CREATE TABLE persons (
    person_id    SERIAL PRIMARY KEY,
    tenant_id    INT NOT NULL REFERENCES tenants(tenant_id),
    position_id  INT REFERENCES positions(position_id),
    first_name   VARCHAR(100) NOT NULL,
    last_name    VARCHAR(100) NOT NULL,
    email        VARCHAR(150) UNIQUE,
    status       VARCHAR(20) NOT NULL DEFAULT 'activo'
                   CHECK (status IN ('activo','inactivo')),
    created_at   TIMESTAMP NOT NULL DEFAULT now(),
    updated_at   TIMESTAMP NOT NULL DEFAULT now()
);

-- =========================================================
-- Sistemas SST (catálogo) y habilitación por organización
-- =========================================================
CREATE TABLE type_system_sst (
    system_id    SERIAL PRIMARY KEY,
    name         VARCHAR(80) NOT NULL UNIQUE,
    description  TEXT
);

CREATE TABLE tenantsystems (
    tenant_system_id SERIAL PRIMARY KEY,
    tenant_id        INT NOT NULL REFERENCES tenants(tenant_id),
    system_id        INT NOT NULL REFERENCES type_system_sst(system_id),
    enabled_at       TIMESTAMP NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, system_id)
);

-- =========================================================
-- Módulos y asignación por organización
-- =========================================================
CREATE TABLE modules (
    module_id      SERIAL PRIMARY KEY,
    system_id      INT NOT NULL REFERENCES type_system_sst(system_id),
    title          VARCHAR(150) NOT NULL,
    description    TEXT,
    display_order  INT
);

CREATE TABLE tenant_modules (
    tenant_module_id SERIAL PRIMARY KEY,
    tenant_id        INT NOT NULL REFERENCES tenants(tenant_id),
    module_id        INT NOT NULL REFERENCES modules(module_id),
    assigned_at      TIMESTAMP NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, module_id)
);

-- =========================================================
-- Formatos (asociados a un módulo)
-- =========================================================
CREATE TABLE formats_sst (
    format_id    SERIAL PRIMARY KEY,
    module_id    INT NOT NULL REFERENCES modules(module_id),
    name         VARCHAR(150) NOT NULL,
    description  TEXT
);

-- =========================================================
-- Etapas del ciclo PHVA
-- =========================================================
CREATE TABLE phva_stages (
    phva_stage_id SERIAL PRIMARY KEY,
    name          VARCHAR(20) NOT NULL UNIQUE
                    CHECK (name IN ('Planear','Hacer','Verificar','Actuar'))
);

-- =========================================================
-- Plantillas asignadas a la organización (documentos)
-- =========================================================
CREATE TABLE tenanttemplates (
    template_id    SERIAL PRIMARY KEY,
    tenant_id      INT NOT NULL REFERENCES tenants(tenant_id),
    system_id      INT NOT NULL REFERENCES type_system_sst(system_id),
    phva_stage_id  INT NOT NULL REFERENCES phva_stages(phva_stage_id),
    format_id      INT NOT NULL REFERENCES formats_sst(format_id),
    status         VARCHAR(20) NOT NULL DEFAULT 'no_iniciado'
                     CHECK (status IN ('finalizado','borrador','pendiente','no_iniciado')),
    updated_by     VARCHAR(100),
    created_at     TIMESTAMP NOT NULL DEFAULT now(),
    updated_at     TIMESTAMP NOT NULL DEFAULT now()
);

-- =========================================================
-- Evaluaciones
-- =========================================================
CREATE TABLE evaluations (
    evaluation_id SERIAL PRIMARY KEY,
    tenant_id     INT NOT NULL REFERENCES tenants(tenant_id),
    module_id     INT REFERENCES modules(module_id),
    name          VARCHAR(150) NOT NULL,
    description   TEXT,
    created_at    TIMESTAMP NOT NULL DEFAULT now()
);

-- =========================================================
-- Bloqueos de edición
-- =========================================================
CREATE TABLE editing_locks (
    lock_id      SERIAL PRIMARY KEY,
    template_id  INT NOT NULL REFERENCES tenanttemplates(template_id),
    locked_by    VARCHAR(100) NOT NULL,
    locked_at    TIMESTAMP NOT NULL DEFAULT now(),
    expires_at   TIMESTAMP NOT NULL,
    active       BOOLEAN NOT NULL DEFAULT TRUE
);

-- =========================================================
-- Auditoría de organizaciones
-- =========================================================
CREATE TABLE tenant_audit_log (
    audit_id     SERIAL PRIMARY KEY,
    tenant_id    INT NOT NULL REFERENCES tenants(tenant_id),
    field_name   VARCHAR(100) NOT NULL,
    old_value    TEXT,
    new_value    TEXT,
    changed_by   VARCHAR(100),
    changed_at   TIMESTAMP NOT NULL DEFAULT now()
);

-- =========================================================
-- Vistas materializadas (mencionadas explícitamente en el enunciado)
-- =========================================================
CREATE MATERIALIZED VIEW vm_template_sst_docs_summary AS
SELECT
    t.tenant_id,
    t.name AS tenant_name,
    COUNT(*) AS total_documentos,
    COUNT(*) FILTER (WHERE tt.status = 'finalizado')  AS finalizados,
    COUNT(*) FILTER (WHERE tt.status = 'borrador')     AS en_borrador,
    COUNT(*) FILTER (WHERE tt.status = 'no_iniciado')  AS no_iniciados,
    COUNT(*) FILTER (WHERE tt.status = 'pendiente')    AS pendientes,
    ROUND(100.0 * COUNT(*) FILTER (WHERE tt.status = 'finalizado')
          / NULLIF(COUNT(*), 0), 2) AS porcentaje_cumplimiento
FROM tenants t
JOIN tenanttemplates tt ON tt.tenant_id = t.tenant_id
JOIN type_system_sst s ON s.system_id = tt.system_id
WHERE s.name = 'Sistema de Gestión SST'
GROUP BY t.tenant_id, t.name;

CREATE MATERIALIZED VIEW vm_template_pesv_docs_summary AS
SELECT
    t.tenant_id,
    t.name AS tenant_name,
    COUNT(*) AS total_documentos,
    COUNT(*) FILTER (WHERE tt.status = 'finalizado')  AS finalizados,
    COUNT(*) FILTER (WHERE tt.status = 'borrador')     AS en_borrador,
    COUNT(*) FILTER (WHERE tt.status = 'no_iniciado')  AS no_iniciados,
    COUNT(*) FILTER (WHERE tt.status = 'pendiente')    AS pendientes,
    ROUND(100.0 * COUNT(*) FILTER (WHERE tt.status = 'finalizado')
          / NULLIF(COUNT(*), 0), 2) AS porcentaje_cumplimiento
FROM tenants t
JOIN tenanttemplates tt ON tt.tenant_id = t.tenant_id
JOIN type_system_sst s ON s.system_id = tt.system_id
WHERE s.name = 'Plan Estratégico de Seguridad Vial (PESV)'
GROUP BY t.tenant_id, t.name;