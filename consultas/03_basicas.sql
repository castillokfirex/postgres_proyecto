-- 1. Consultar todos los registros de la tabla tenants, mostrando toda la información disponible.
SELECT * FROM tenants;

-- 2. Consultar el nombre, correo de contacto y teléfono de todas las organizaciones registradas en tenants.
SELECT name, contact_email, contact_phone FROM tenants;

-- 3. Listar las personas registradas en persons, mostrando nombres, apellidos y correo electrónico.
SELECT first_name, last_name, email FROM persons;

-- 4. Consultar las personas cuyo estado (is_active) se encuentre activo.
SELECT * FROM persons WHERE is_active = true;

-- 5. Obtener las organizaciones cuyo nombre contenga una palabra dada como criterio de búsqueda.
SELECT * FROM tenants WHERE name LIKE '%Log%';

-- 6. Listar todos los países de countries, ordenados alfabéticamente por nombre.
SELECT * FROM countries ORDER BY name ASC;

-- 7. Consultar los departamentos pertenecientes a un país determinado.
SELECT * FROM departments WHERE country_id = 1;

-- 8. Listar los municipios correspondientes a un departamento específico.
SELECT * FROM municipalities WHERE department_id = 1;

-- 9. Consultar todos los cargos de positions, ordenados por descripción.
SELECT * FROM positions ORDER BY description ASC;

-- 10. Consultar las personas que pertenezcan a una organización determinada mediante tenant_id.
SELECT p.* FROM persons p INNER JOIN positions pos ON p.position_id = pos.id WHERE pos.tenant_id = 2;

-- 11. Obtener las organizaciones que actualmente estén activas.
SELECT * FROM tenants WHERE is_active = true;

-- 12. Identificar las organizaciones registradas dentro de un período determinado.
SELECT * FROM tenants WHERE created_at BETWEEN '2023-01-01 00:00:00' AND '2030-12-31 23:59:59';

-- 13. Listar los diferentes tamaños de empresa de tenant_sizes.
SELECT * FROM tenant_sizes;

-- 14. Consultar los diferentes tipos de sistemas SST de type_system_sst.
SELECT * FROM type_system_sst;

-- 15. Listar los módulos del sistema mostrando título, descripción y orden de presentación.
SELECT title, description, "order" FROM modules;
