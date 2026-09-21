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