BEGIN;

-- ==============================================================================
-- 1. countries
-- ==============================================================================
INSERT INTO countries (id, name, code) VALUES
(1, 'Colombia', 'COL'),
(2, 'México', 'MEX'),
(3, 'Argentina', 'ARG');
-- Reset sequence
SELECT setval('countries_id_seq', (SELECT MAX(id) FROM countries));

-- ==============================================================================
-- 2. departments
-- ==============================================================================
INSERT INTO departments (id, country_id, name) VALUES
(1, 1, 'Antioquia'),
(2, 1, 'Cundinamarca'),
(3, 1, 'Valle del Cauca'),
(4, 1, 'Atlántico'),
(5, 1, 'Santander');
-- Reset sequence
SELECT setval('departments_id_seq', (SELECT MAX(id) FROM departments));

-- ==============================================================================
-- 3. municipalities
-- ==============================================================================
INSERT INTO municipalities (id, department_id, name) VALUES
(1, 1, 'Medellín'),
(2, 1, 'Bello'),
(3, 2, 'Bogotá D.C.'),
(4, 2, 'Soacha'),
(5, 3, 'Cali'),
(6, 3, 'Palmira'),
(7, 4, 'Barranquilla'),
(8, 4, 'Soledad'),
(9, 5, 'Bucaramanga'),
(10, 5, 'Floridablanca');
-- Reset sequence
SELECT setval('municipalities_id_seq', (SELECT MAX(id) FROM municipalities));

-- ==============================================================================
-- 4. tenant_sizes
-- ==============================================================================
INSERT INTO tenant_sizes (id, name, description) VALUES
(1, 'Microempresa', 'Empresa con hasta 10 trabajadores.'),
(2, 'Pequeña Empresa', 'Empresa de 11 a 50 trabajadores.'),
(3, 'Mediana Empresa', 'Empresa de 51 a 200 trabajadores.'),
(4, 'Gran Empresa', 'Empresa de más de 200 trabajadores.');
-- Reset sequence
SELECT setval('tenant_sizes_id_seq', (SELECT MAX(id) FROM tenant_sizes));

-- ==============================================================================
-- 5. type_system_sst
-- ==============================================================================
INSERT INTO type_system_sst (id, name, description) VALUES
(1, 'SG-SST', 'Sistema de Gestión de Seguridad y Salud en el Trabajo (Resolución 0312).'),
(2, 'PESV', 'Plan Estratégico de Seguridad Vial.');
-- Reset sequence
SELECT setval('type_system_sst_id_seq', (SELECT MAX(id) FROM type_system_sst));

-- ==============================================================================
-- 6. stages_phva
-- ==============================================================================
INSERT INTO stages_phva (id, name, "order") VALUES
(1, 'Planear', 1),
(2, 'Hacer', 2),
(3, 'Verificar', 3),
(4, 'Actuar', 4);
-- Reset sequence
SELECT setval('stages_phva_id_seq', (SELECT MAX(id) FROM stages_phva));

-- ==============================================================================
-- 7. positions
-- ==============================================================================
INSERT INTO positions (id, tenant_id, name, description) VALUES
(1, 1, 'Gerente General', 'Representante legal.'),
(2, 1, 'Líder SST', 'Responsable del SG-SST.'),
(3, 1, 'Asistente Administrativo', 'Apoyo en tareas de oficina.'),
(4, 2, 'Gerente General', 'Representante legal.'),
(5, 2, 'Director de Recursos Humanos', 'Encargado del personal.'),
(6, 2, 'Líder SST', 'Responsable del SG-SST.'),
(7, 2, 'Coordinador Operativo', 'Supervisa en campo.'),
(8, 3, 'Gerente General', 'Representante legal.'),
(9, 3, 'Coordinador Operativo', 'Supervisa en campo.'),
(10, 3, 'Auditor Interno', 'Realiza auditorías.'),
(11, 4, 'Gerente General', 'Representante legal.'),
(12, 4, 'Líder SST', 'Responsable del SG-SST.'),
(13, 4, 'Asistente Administrativo', 'Apoyo en tareas.');
-- Reset sequence
SELECT setval('positions_id_seq', (SELECT MAX(id) FROM positions));

-- ==============================================================================
-- 8. modules
-- ==============================================================================
INSERT INTO modules (id, type_system_sst_id, title, description, "order") VALUES
-- Módulos para SG-SST (1)
(1, 1, 'Identificación de Peligros y Riesgos', 'Matriz de peligros, valoración de riesgos y determinación de controles.', 1),
(2, 1, 'Políticas y Objetivos SST', 'Definición de la política de seguridad y objetivos anuales.', 2),
(3, 1, 'Capacitación y Entrenamiento', 'Programa de inducción, capacitación y entrenamiento.', 3),
(4, 1, 'Auditoría Interna SST', 'Revisión por la alta dirección y auditorías internas.', 4),
(5, 1, 'Planes de Emergencia', 'Prevención, preparación y respuesta ante emergencias.', 5),
-- Módulos para PESV (2)
(6, 2, 'Gestión Institucional', 'Comité de seguridad vial y políticas de seguridad.', 1),
(7, 2, 'Vehículos Seguros', 'Plan de mantenimiento preventivo y correctivo de la flota.', 2),
(8, 2, 'Comportamiento Humano', 'Pruebas y capacitaciones para conductores.', 3);
-- Reset sequence
SELECT setval('modules_id_seq', (SELECT MAX(id) FROM modules));

-- ==============================================================================
-- 9. tenants
-- ==============================================================================
INSERT INTO tenants (id, tenant_size_id, municipality_id, name, nit, contact_email, contact_phone, address, is_active) VALUES
(1, 1, 1, 'Tecnologías del Valle SAS', '900111222-1', 'contacto@tecnivalle.com', '3001234567', 'Cra 45 # 12-34', TRUE),
(2, 2, 3, 'Logística Nacional de Carga Ltda', '800333444-2', 'gerencia@logistica.com.co', '3109876543', 'Av Calle 26 # 68-50', TRUE),
(3, 3, 5, 'Manufacturas Caleñas SA', '830555666-3', 'info@manufacturascali.com', '3205551122', 'Calle 10 # 5-60', TRUE),
(4, 4, 7, 'Industrias Costeñas', '901777888-4', 'admin@industriascosta.com', '3157778899', 'Via 40 # 70-15', FALSE), -- Inactivo
(5, 2, 9, 'Servicios Globales Bucaramanga', '900999000-5', 'soporte@serviciosg.com', '3119990000', 'Cra 27 # 36-14', TRUE); -- Sin personas
-- Reset sequence
SELECT setval('tenants_id_seq', (SELECT MAX(id) FROM tenants));

-- ==============================================================================
-- 10. persons
-- ==============================================================================
INSERT INTO persons (id, position_id, first_name, last_name, email, document_number, is_active) VALUES
-- Tenant 1 (3 personas)
(1, 1, 'Carlos', 'Pérez', 'cperez@tecnivalle.com', '10101010', TRUE),
(2, 2, 'Ana', 'Gómez', 'agomez@tecnivalle.com', '20202020', TRUE),
(3, 3, 'Luis', 'Martínez', 'lmartinez@tecnivalle.com', '30303030', TRUE),
-- Tenant 2 (4 personas)
(4, 4, 'María', 'Rodríguez', 'mrodriguez@logistica.com.co', '40404040', TRUE),
(5, 5, 'Jorge', 'López', 'jlopez@logistica.com.co', '50505050', TRUE),
(6, 6, 'Diana', 'García', 'dgarcia@logistica.com.co', '60606060', TRUE),
(7, 7, 'Andrés', 'Sánchez', 'asanchez@logistica.com.co', '70707070', TRUE),
-- Tenant 3 (3 personas)
(8, 8, 'Pedro', 'Ramírez', 'pramirez@manufacturascali.com', '80808080', TRUE),
(9, 9, 'Laura', 'Torres', 'ltorres@manufacturascali.com', '90909090', TRUE),
(10, 10, 'Diego', 'Flores', 'dflores@manufacturascali.com', '11111111', TRUE),
-- Tenant 4 (3 personas, organización inactiva)
(11, 11, 'Elena', 'Díaz', 'ediaz@industriascosta.com', '22222222', TRUE),
(12, 12, 'Camilo', 'Ruiz', 'cruiz@industriascosta.com', '33333333', TRUE),
(13, 13, 'Sara', 'Herrera', 'sherrera@industriascosta.com', '44444444', TRUE);
-- Tenant 5 no tiene personas, según las reglas

-- Reset sequence
SELECT setval('persons_id_seq', (SELECT MAX(id) FROM persons));

-- ==============================================================================
-- 11. tenantsystems
-- ==============================================================================
INSERT INTO tenantsystems (id, tenant_id, type_system_sst_id, is_active) VALUES
(1, 1, 1, TRUE),   -- T1: SG-SST
(2, 2, 1, TRUE),   -- T2: SG-SST
(3, 2, 2, TRUE),   -- T2: PESV
(4, 3, 2, TRUE),   -- T3: PESV
(5, 4, 1, FALSE),  -- T4: SG-SST
(6, 4, 2, FALSE),  -- T4: PESV
(7, 5, 1, TRUE);   -- T5: SG-SST
-- Reset sequence
SELECT setval('tenantsystems_id_seq', (SELECT MAX(id) FROM tenantsystems));

-- ==============================================================================
-- 12. tenant_modules
-- ==============================================================================
INSERT INTO tenant_modules (id, tenant_id, module_id, is_active) VALUES
-- T1 (SG-SST) no tiene 100%
(1, 1, 1, TRUE),
(2, 1, 2, TRUE),
(3, 1, 3, TRUE),
-- T2 (SG-SST, PESV)
(4, 2, 1, TRUE),
(5, 2, 4, TRUE),
(6, 2, 6, TRUE),
(7, 2, 7, TRUE),
-- T3 (PESV)
(8, 3, 6, TRUE),
(9, 3, 7, TRUE),
-- T4 (SG-SST, PESV)
(10, 4, 2, FALSE),
(11, 4, 5, FALSE),
(12, 4, 8, FALSE),
-- T5 (SG-SST)
(13, 5, 1, TRUE),
(14, 5, 4, TRUE);
-- Reset sequence
SELECT setval('tenant_modules_id_seq', (SELECT MAX(id) FROM tenant_modules));

-- ==============================================================================
-- 13. templates
-- ==============================================================================
INSERT INTO templates (id, stage_phva_id, module_id, name, description) VALUES
(1, 1, 1, 'Matriz de Identificación de Peligros', 'Plantilla para identificar peligros iniciales.'),
(2, 2, 1, 'Registro de Control de Riesgos', 'Ejecución de las medidas preventivas.'),
(3, 1, 2, 'Documento de Política SST', 'Declaración firmada de compromisos.'),
(4, 1, 3, 'Cronograma de Capacitaciones', 'Planificación anual de charlas y cursos.'),
(5, 2, 3, 'Lista de Asistencia a Capacitaciones', 'Formato para firmar asistencia de trabajadores.'),
(6, 3, 4, 'Plan de Auditoría', 'Programación de la auditoría interna.'),
(7, 3, 4, 'Informe de Auditoría Interna', 'Hallazgos de la auditoría.'),
(8, 4, 5, 'Simulacro de Evacuación', 'Reporte del simulacro anual ejecutado.'),
(9, 4, 5, 'Plan de Mejora Continua', 'Acciones correctivas basadas en auditoría.'),
(10, 1, 6, 'Acta de Conformación Comité de Seguridad Vial', 'Documento que oficializa el comité PESV.'),
(11, 2, 6, 'Política de Regulación de Velocidad', 'Normativa interna para la flota.'),
(12, 2, 7, 'Ficha de Mantenimiento Preventivo', 'Checklist mensual de revisión vehicular.'),
(13, 3, 7, 'Inspección Pre-operacional', 'Revisión diaria antes de la ruta.'),
(14, 1, 8, 'Perfil del Conductor', 'Requisitos y competencias para contratación.'),
(15, 4, 8, 'Evaluación Práctica de Conducción', 'Examen anual de destrezas al volante.');
-- Reset sequence
SELECT setval('templates_id_seq', (SELECT MAX(id) FROM templates));

-- ==============================================================================
-- 14. formats_sst
-- ==============================================================================
INSERT INTO formats_sst (id, module_id, name, description) VALUES
(1, 1, 'Formato GTC-45', 'Formato basado en la Guía Técnica Colombiana 45 para riesgos.'),
(2, 3, 'Formato FOR-CAP-01', 'Formato estándar de asistencia técnica.'),
(3, 4, 'Formato AUD-01', 'Cuestionario de verificación normativa SG-SST.'),
(4, 7, 'Formato MANT-VEH-01', 'Checklist de revisión de llantas, frenos y luces.');
-- Reset sequence
SELECT setval('formats_sst_id_seq', (SELECT MAX(id) FROM formats_sst));

-- ==============================================================================
-- 15. tenant_templates
-- ==============================================================================
INSERT INTO tenant_templates (tenant_id, template_id, format_sst_id, status, completed_at) VALUES
-- T1
(1, 1, 1, 'finalizado', '2023-05-10 10:00:00'),
(1, 3, NULL, 'borrador', NULL),
(1, 4, NULL, 'no_iniciado', NULL),
-- T2 (variados)
(2, 1, 1, 'finalizado', '2023-01-15 08:30:00'),
(2, 6, 3, 'pendiente', NULL),
(2, 10, NULL, 'finalizado', '2023-02-20 14:00:00'),
(2, 12, 4, 'borrador', NULL),
-- T3 (solo PESV)
(3, 10, NULL, 'finalizado', '2023-03-05 09:15:00'),
(3, 11, NULL, 'borrador', NULL),
(3, 13, 4, 'no_iniciado', NULL),
-- T4 (inactivo)
(4, 3, NULL, 'no_iniciado', NULL),
(4, 9, NULL, 'no_iniciado', NULL),
(4, 14, NULL, 'borrador', NULL),
-- T5 (sin personas pero con asignaciones)
(5, 1, 1, 'no_iniciado', NULL),
(5, 6, 3, 'no_iniciado', NULL);

-- ==============================================================================
-- 16. evaluations
-- ==============================================================================
INSERT INTO evaluations (tenant_id, template_id, name, description, score, evaluated_at) VALUES
(1, 1, 'Evaluación Inicial SG-SST 2023', 'Revisión de la matriz de peligros.', 85.50, '2023-06-01 10:00:00'),
(2, 10, 'Auditoría Comité PESV', 'Verificación de actas de constitución.', 92.00, '2023-03-01 11:30:00'),
(3, 10, 'Evaluación Documental PESV', 'Revisión inicial del plan estratégico.', 60.00, '2023-04-10 15:00:00');

-- ==============================================================================
-- 17. editing_locks
-- ==============================================================================
INSERT INTO editing_locks (resource_type, resource_id, locked_by, locked_at, expires_at) VALUES
('template', 3, 2, NOW() - INTERVAL '2 days', NOW() - INTERVAL '1 day'), -- Vencido (en el pasado)
('template', 12, 6, NOW(), NOW() + INTERVAL '1 hour'); -- Activo (en el futuro)

-- ==============================================================================
-- 18. audit_tenants
-- ==============================================================================
INSERT INTO audit_tenants (tenant_id, field_changed, old_value, new_value, changed_by) VALUES
(4, 'is_active', 'true', 'false', 'Sistema Admin'),
(1, 'address', 'Calle Falsa 123', 'Cra 45 # 12-34', 'cperez@tecnivalle.com');

COMMIT;
