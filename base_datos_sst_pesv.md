# Base de datos SST/PESV — Modelo y datos de prueba

Basado estrictamente en `Examen.md`: solo se incluyen las tablas exigidas o implicadas por los componentes y consultas del enunciado (Empresas, Personas, Cargos, Sistemas SST, Módulos, Etapas PHVA, Plantillas, Formatos, Evaluaciones, Ubicación geográfica, Bloqueos, Auditoría), más las dos vistas materializadas que el enunciado nombra explícitamente. No se agregan tablas adicionales.

## 1. Diccionario rápido de tablas

| Tabla | Corresponde a |
|---|---|
| `countries` | Países |
| `states` | Departamentos o regiones |
| `cities` | Municipios o ciudades |
| `tenant_sizes` | Tamaños de empresa |
| `tenants` | Empresas / organizaciones (multi-tenant) |
| `positions` | Cargos (propios de cada organización) |
| `persons` | Personas / trabajadores |
| `type_system_sst` | Catálogo de sistemas SST (SST, PESV) |
| `tenantsystems` | Sistemas habilitados por organización |
| `modules` | Módulos funcionales (pertenecen a un sistema) |
| `tenant_modules` | Módulos habilitados por organización |
| `formats_sst` | Formatos (pertenecen a un módulo) |
| `phva_stages` | Etapas del ciclo PHVA |
| `tenanttemplates` | Plantillas/documentos asignados a una organización |
| `evaluations` | Evaluaciones |
| `editing_locks` | Bloqueos de edición |
| `tenant_audit_log` | Auditoría de cambios sobre organizaciones |

Vistas materializadas (nombradas en el enunciado, consulta 3.22): `vm_template_sst_docs_summary`, `vm_template_pesv_docs_summary`.

---

## 2. Script DDL

```sql
-- =========================================================
-- Ubicación geográfica
-- =========================================================
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
```

---

## 3. Datos de prueba

La información fue diseñada a propósito para que **cada bloque de consultas del enunciado** (básicas, intermedias, avanzadas, vistas y vistas materializadas) tenga al menos un resultado: hay una organización sin personas, un módulo sin asignar a ninguna organización, una organización con módulos pero sin plantillas, dos organizaciones en la misma ciudad con tamaño distinto, una organización con plantillas en las cuatro etapas PHVA, una organización inactiva, cargos con más de una persona, y bloqueos activos e inactivos.

```sql
-- Países, departamentos, municipios
INSERT INTO countries (name) VALUES
('Colombia'), ('México');

INSERT INTO states (country_id, name) VALUES
(1, 'Santander'), (1, 'Antioquia'), (2, 'Jalisco');

INSERT INTO cities (state_id, name) VALUES
(1, 'Bucaramanga'), (1, 'Floridablanca'), (2, 'Medellín'), (3, 'Guadalajara');

-- Tamaños de empresa
INSERT INTO tenant_sizes (name, description) VALUES
('Pequeña', 'Hasta 50 trabajadores'),
('Mediana', 'Entre 51 y 200 trabajadores'),
('Grande', 'Más de 200 trabajadores');

-- Organizaciones
INSERT INTO tenants (name, nit, contact_email, contact_phone, tenant_size_id, city_id, status) VALUES
('Constructora ABC S.A.S.',        '900123456-1', 'contacto@abc.com',              '6076001122', 2, 1, 'activo'),
('Transportes Rápidos Ltda.',      '900234567-2', 'info@transportesrapidos.com',   '6076002233', 3, 1, 'activo'),
('Textiles del Norte S.A.S.',      '900345678-3', 'gerencia@textilesnorte.com',    '6076003344', 1, 2, 'activo'),
('Minerales de Antioquia S.A.S.',  '900456789-4', 'contacto@mineralesantioquia.com','6044001122', 3, 3, 'inactivo'),
('Logística Global S.A.S.',        '900567890-5', 'info@logisticaglobal.com',      '6044002233', 2, 3, 'activo');

-- Cargos (propios de cada organización)
INSERT INTO positions (tenant_id, description) VALUES
(1, 'Gerente SST'), (1, 'Coordinador PESV'), (1, 'Auxiliar Administrativo'),
(2, 'Conductor'), (2, 'Coordinador PESV'), (2, 'Jefe de Operaciones'),
(3, 'Operario de Producción'), (3, 'Gerente SST'),
(4, 'Supervisor de Seguridad'), (4, 'Operario Minero');

-- Personas (tenant 5 se deja sin personas a propósito)
INSERT INTO persons (tenant_id, position_id, first_name, last_name, email, status) VALUES
(1, 1, 'Laura',   'Martínez', 'laura.martinez@abc.com',                    'activo'),
(1, 2, 'Carlos',  'Pérez',    'carlos.perez@abc.com',                      'activo'),
(1, 3, 'Diana',   'Gómez',    'diana.gomez@abc.com',                       'inactivo'),
(1, 1, 'Andrés',  'Rojas',    'andres.rojas@abc.com',                      'activo'),
(2, 4, 'Jorge',   'Suárez',   'jorge.suarez@transportesrapidos.com',       'activo'),
(2, 4, 'Pedro',   'Ramírez',  'pedro.ramirez@transportesrapidos.com',      'activo'),
(2, 4, 'Luis',    'Cárdenas', 'luis.cardenas@transportesrapidos.com',      'activo'),
(2, 5, 'Marta',   'Londoño',  'marta.londono@transportesrapidos.com',      'activo'),
(2, 6, 'Sofía',   'Duarte',   'sofia.duarte@transportesrapidos.com',       'activo'),
(3, 7, 'Ricardo', 'Vargas',   'ricardo.vargas@textilesnorte.com',          'activo'),
(3, 8, 'Patricia','León',     'patricia.leon@textilesnorte.com',           'activo'),
(4, 9, 'Fernando','Castaño',  'fernando.castano@mineralesantioquia.com',   'inactivo'),
(4, 10,'Camilo',  'Zapata',   'camilo.zapata@mineralesantioquia.com',      'inactivo');

-- Catálogo de sistemas SST
INSERT INTO type_system_sst (name, description) VALUES
('Sistema de Gestión SST', 'Sistema de Gestión de Seguridad y Salud en el Trabajo'),
('Plan Estratégico de Seguridad Vial (PESV)', 'Gestión de la seguridad vial de la organización');

-- Sistemas habilitados por organización (tenant 3 solo tiene SST, tenant 5 solo PESV)
INSERT INTO tenantsystems (tenant_id, system_id) VALUES
(1, 1), (1, 2),
(2, 1), (2, 2),
(3, 1),
(4, 1), (4, 2),
(5, 2);

-- Módulos (module 4 se deja sin asignar a ninguna organización a propósito)
INSERT INTO modules (system_id, title, description, display_order) VALUES
(1, 'Identificación de Peligros',   'Módulo de identificación de peligros y riesgos', 1),
(1, 'Capacitaciones SST',           'Gestión de capacitaciones en SST',               2),
(1, 'Indicadores SST',              'Indicadores de gestión SST',                     3),
(1, 'Inspecciones de Seguridad',    'Módulo de inspecciones planificadas',            4),
(2, 'Diagnóstico PESV',             'Diagnóstico inicial de seguridad vial',          1),
(2, 'Plan de Acción PESV',          'Definición del plan de acción vial',             2),
(2, 'Capacitación Vial',            'Capacitación en seguridad vial',                 3);

-- Módulos habilitados por organización
-- Tenant 2 tiene TODOS los módulos del sistema PESV (5,6,7)
INSERT INTO tenant_modules (tenant_id, module_id) VALUES
(1, 1), (1, 2), (1, 3), (1, 5), (1, 6),
(2, 1), (2, 2), (2, 3), (2, 5), (2, 6), (2, 7),
(3, 1),
(4, 1), (4, 2), (4, 5);

-- Formatos (uno por módulo)
INSERT INTO formats_sst (module_id, name, description) VALUES
(1, 'Matriz de Peligros y Riesgos',      'Formato para identificación de peligros'),
(2, 'Registro de Capacitación',          'Formato de asistencia y contenido de capacitación'),
(3, 'Indicador de Accidentalidad',       'Formato de seguimiento de indicadores'),
(4, 'Formato de Inspección Planificada', 'Formato de inspecciones de seguridad'),
(5, 'Diagnóstico Vial Inicial',          'Formato de diagnóstico PESV'),
(6, 'Plan de Acción Vial',               'Formato de plan de acción PESV'),
(7, 'Registro de Capacitación Vial',     'Formato de capacitación en seguridad vial');

-- Etapas PHVA
INSERT INTO phva_stages (name) VALUES
('Planear'), ('Hacer'), ('Verificar'), ('Actuar');

-- Plantillas asignadas (documentos)
-- Tenant 1 y 2 cubren las 4 etapas PHVA; tenant 3 no tiene ninguna plantilla (aunque sí módulos);
-- tenant 4 (inactivo) solo cubre 2 etapas; tenant 5 no tiene ninguna.
INSERT INTO tenanttemplates (tenant_id, system_id, phva_stage_id, format_id, status, updated_by) VALUES
(1, 1, 1, 1, 'finalizado',  'laura.martinez'),
(1, 1, 2, 2, 'borrador',    'carlos.perez'),
(1, 1, 3, 3, 'pendiente',   'laura.martinez'),
(1, 2, 4, 6, 'no_iniciado', NULL),
(1, 2, 1, 5, 'finalizado',  'carlos.perez'),
(2, 1, 1, 1, 'finalizado',  'jorge.suarez'),
(2, 1, 1, 2, 'finalizado',  'pedro.ramirez'),
(2, 1, 2, 3, 'finalizado',  'marta.londono'),
(2, 2, 3, 6, 'borrador',    'sofia.duarte'),
(2, 2, 4, 7, 'pendiente',   'jorge.suarez'),
(4, 1, 1, 1, 'finalizado',  'fernando.castano'),
(4, 1, 2, 2, 'pendiente',   'camilo.zapata');

-- Evaluaciones
INSERT INTO evaluations (tenant_id, module_id, name, description) VALUES
(1, 2, 'Evaluación de Capacitación en Riesgos Laborales', 'Evaluación aplicada tras la capacitación SST'),
(2, 7, 'Evaluación de Capacitación Vial',                 'Evaluación aplicada tras la capacitación PESV'),
(3, 1, 'Evaluación Inicial de Peligros',                  'Evaluación diagnóstica de peligros identificados');

-- Bloqueos de edición (uno activo, uno vencido/inactivo)
INSERT INTO editing_locks (template_id, locked_by, locked_at, expires_at, active) VALUES
(2, 'carlos.perez', now() - INTERVAL '10 minutes', now() + INTERVAL '20 minutes', TRUE),
(9, 'sofia.duarte',  now() - INTERVAL '2 days',     now() - INTERVAL '1 day',      FALSE);

-- Auditoría de organizaciones
INSERT INTO tenant_audit_log (tenant_id, field_name, old_value, new_value, changed_by) VALUES
(4, 'status',         'activo',       'inactivo',      'admin'),
(1, 'contact_phone',  '6076001111',   '6076001122',    'admin');

-- Refrescar las vistas materializadas con los datos ya cargados
REFRESH MATERIALIZED VIEW vm_template_sst_docs_summary;
REFRESH MATERIALIZED VIEW vm_template_pesv_docs_summary;
```

---

## 4. Qué queda cubierto con estos datos

- **Tenants**: 5 organizaciones (4 activas, 1 inactiva), en 3 ciudades distintas; 2 de ellas (`Constructora ABC` y `Transportes Rápidos`) comparten ciudad (Bucaramanga) con tamaño diferente.
- **Persons**: la organización 5 no tiene personas (para pruebas de `LEFT JOIN` / organizaciones sin personas); el cargo "Gerente SST" del tenant 1 tiene 2 personas, para probar comparaciones contra el promedio de ocupación de cargos.
- **Modules**: el módulo "Inspecciones de Seguridad" no está asignado a ninguna organización; el tenant 2 tiene habilitados todos los módulos del sistema PESV.
- **Tenanttemplates**: los tenants 1 y 2 tienen plantillas en las 4 etapas PHVA; el tenant 3 tiene módulos pero cero plantillas; el tenant 4 solo cubre 2 de las 4 etapas; el tenant 5 no tiene ninguna.
- **Editing_locks**: un bloqueo activo y uno vencido/inactivo.
- **Tenant_audit_log**: un cambio de estado y un cambio de dato de contacto, ya registrados.
