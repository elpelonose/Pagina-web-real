-- Resetear la base de datos
DROP DATABASE IF EXISTS db_sistema_academico;
CREATE DATABASE db_sistema_academico CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE db_sistema_academico;

-- ============================================================================
-- 1. CATÁLOGOS DE SEGURIDAD Y UBICACIÓN
-- ============================================================================

-- Tabla de Roles (Admin, Maestro, Alumno)
CREATE TABLE roles (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'ID del rol',
    nombre VARCHAR(30) NOT NULL UNIQUE COMMENT 'Ej: Admin, Maestro, Alumno',
    descripcion VARCHAR(100) COMMENT 'Descripción de los permisos del rol'
) COMMENT='Roles del sistema para control de acceso';

-- Ubigeo normalizado
CREATE TABLE ubigeo (
    codigo VARCHAR(6) PRIMARY KEY COMMENT 'Código UBIGEO de 6 dígitos',
    departamento VARCHAR(50) NOT NULL,
    provincia VARCHAR(50) NOT NULL,
    distrito VARCHAR(50) NOT NULL
) COMMENT='Catálogo de ubicación geográfica';

-- ============================================================================
-- 2. USUARIOS Y PERFILES (General para Alumnos, Maestros y Admins)
-- ============================================================================

-- Tabla Central de Usuarios (Login y Autenticación)
CREATE TABLE usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'ID interno del usuario',
    id_rol INT NOT NULL COMMENT 'Relación con la tabla roles',
    codigo_institucional VARCHAR(20) UNIQUE COMMENT 'Código único (Ej: RC23003 para alumno, DOC101 para maestro)',
    dni VARCHAR(8) NOT NULL UNIQUE COMMENT 'DNI de 8 dígitos',
    primer_apellido VARCHAR(50) NOT NULL,
    segundo_apellido VARCHAR(50) NOT NULL,
    nombres VARCHAR(100) NOT NULL,
    correo VARCHAR(100) NOT NULL UNIQUE COMMENT 'Correo institucional o personal',
    clave VARCHAR(255) NOT NULL COMMENT 'Contraseña encriptada (Hash)',
    token VARCHAR(255) NULL COMMENT 'Token de sesión o recuperación',
    sexo ENUM('M', 'F') NOT NULL,
    telefono VARCHAR(15),
    direccion VARCHAR(200),
    codigo_ubigeo VARCHAR(6),
    estado ENUM('Activo', 'Inactivo') DEFAULT 'Activo' COMMENT 'Estado de la cuenta',
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha y hora de creación de la cuenta',
    FOREIGN KEY (id_rol) REFERENCES roles(id),
    FOREIGN KEY (codigo_ubigeo) REFERENCES ubigeo(codigo)
) COMMENT='Usuarios del sistema (Alumnos, Docentes y Administradores)';

-- Contactos de Emergencia (Aplica principalmente a alumnos)
CREATE TABLE contactos_emergencia (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL UNIQUE COMMENT 'Usuario al que pertenece el contacto',
    nombre_contacto VARCHAR(150) NOT NULL,
    telefono VARCHAR(15) NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id) ON DELETE CASCADE
) COMMENT='Contactos de emergencia de usuarios';

-- ============================================================================
-- 3. CATÁLOGOS ACADÉMICOS
-- ============================================================================

-- Carreras / Programas de Estudio
CREATE TABLE carreras (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE COMMENT 'Código de carrera (Ej: DPW)',
    nombre VARCHAR(100) NOT NULL,
    resolucion VARCHAR(100)
) COMMENT='Programas de estudio';

-- Unidades Didácticas (Cursos)
CREATE TABLE unidades_didacticas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE COMMENT 'Código de la materia (Ej: UD-101)',
    id_carrera INT NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    creditos DECIMAL(4,1) NOT NULL,
    semestre VARCHAR(20) NOT NULL,
    FOREIGN KEY (id_carrera) REFERENCES carreras(id)
) COMMENT='Unidades didácticas por carrera';

-- ============================================================================
-- 4. MATRÍCULA Y NÓMINA (OPERACIONAL)
-- ============================================================================

-- Cabecera de Matrícula
CREATE TABLE matriculas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL COMMENT 'Alumno matriculado',
    id_carrera INT NOT NULL COMMENT 'Carrera elegida',
    periodo VARCHAR(10) NOT NULL COMMENT 'Ej: 2025-I',
    semestre VARCHAR(20) NOT NULL COMMENT 'Ej: Quinto',
    fecha DATE NOT NULL COMMENT 'Fecha de matriculación',
    total_creditos DECIMAL(4,1) NOT NULL,
    tipo VARCHAR(50) DEFAULT 'Regular',
    CONSTRAINT unq_usuario_periodo UNIQUE(id_usuario, periodo),
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id),
    FOREIGN KEY (id_carrera) REFERENCES carreras(id)
) COMMENT='Matrículas individuales';

-- Detalle de Matrícula (Cursos inscritos)
CREATE TABLE detalle_matricula (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_matricula INT NOT NULL,
    id_unidad INT NOT NULL,
    condicion VARCHAR(50) DEFAULT 'Primera Matricula',
    observacion VARCHAR(100),
    FOREIGN KEY (id_matricula) REFERENCES matriculas(id) ON DELETE CASCADE,
    FOREIGN KEY (id_unidad) REFERENCES unidades_didacticas(id)
) COMMENT='Materias inscritas en la matrícula';

-- Cabecera de Nómina Oficial
CREATE TABLE nominas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_carrera INT NOT NULL,
    periodo VARCHAR(10) NOT NULL COMMENT 'Ej: 2026-II',
    semestre VARCHAR(20) NOT NULL,
    seccion VARCHAR(10) DEFAULT 'Única',
    turno VARCHAR(20) DEFAULT 'Diurno',
    fecha_emision DATE NOT NULL,
    total_hombres INT DEFAULT 0,
    total_mujeres INT DEFAULT 0,
    total_alumnos INT DEFAULT 0,
    FOREIGN KEY (id_carrera) REFERENCES carreras(id)
) COMMENT='Nóminas consolidadas por sección';

-- Detalle de Nómina
CREATE TABLE detalle_nomina (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_nomina INT NOT NULL,
    id_usuario INT NOT NULL COMMENT 'Alumno registrado en la lista',
    numero_orden INT NOT NULL,
    edad INT,
    observacion VARCHAR(10) DEFAULT 'N',
    FOREIGN KEY (id_nomina) REFERENCES nominas(id) ON DELETE CASCADE,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id)
) COMMENT='Relación de alumnos en la nómina';

-- ============================================================================
-- 5. INSERT DE PRUEBA Y ROLES INICIALES
-- ============================================================================

INSERT INTO roles (nombre, descripcion) VALUES 
('Admin', 'Acceso total al sistema y gestión de usuarios'),
('Maestro', 'Docente encargado de dictar unidades didácticas y registrar notas'),
('Alumno', 'Estudiante matriculado con acceso a sus fichas y cursos');

SHOW TABLES;