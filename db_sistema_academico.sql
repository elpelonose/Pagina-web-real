-- 1. Eliminar y recrear la base de datos para limpiar todo
DROP DATABASE IF EXISTS db_sistema_academico;
CREATE DATABASE db_sistema_academico CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE db_sistema_academico;

-- ============================================================================
-- TABLAS MAESTRAS (Datos estáticos y reutilizables)
-- ============================================================================

-- Tabla: Ubigeo (Evita duplicidad de departamentos, provincias y distritos)
CREATE TABLE ubigeo (
    codigo_ubigeo VARCHAR(6) PRIMARY KEY COMMENT 'Código UBIGEO peruano de 6 dígitos',
    departamento VARCHAR(50) NOT NULL COMMENT 'Nombre del departamento',
    provincia VARCHAR(50) NOT NULL COMMENT 'Nombre de la provincia',
    distrito VARCHAR(50) NOT NULL COMMENT 'Nombre del distrito'
) COMMENT='Catálogo estándar de Ubigeos';

-- Tabla: Estudiantes (Datos personales únicos del alumno)
CREATE TABLE estudiantes (
    codigo_estudiante VARCHAR(20) PRIMARY KEY COMMENT 'Código institucional único (Ej: RC23003, RDP26001)',
    dni VARCHAR(8) NOT NULL UNIQUE COMMENT 'Documento Nacional de Identidad',
    primer_apellido VARCHAR(50) NOT NULL COMMENT 'Apellido paterno',
    segundo_apellido VARCHAR(50) NOT NULL COMMENT 'Apellido materno',
    nombres VARCHAR(100) NOT NULL COMMENT 'Nombres completos',
    fecha_nacimiento DATE COMMENT 'Fecha de nacimiento YYYY-MM-DD',
    sexo ENUM('M', 'F') NOT NULL COMMENT 'Sexo biológico: M o F',
    telefono VARCHAR(15) COMMENT 'Teléfono móvil o fijo principal',
    correo VARCHAR(100) COMMENT 'Correo electrónico del estudiante',
    direccion VARCHAR(200) COMMENT 'Dirección de domicilio',
    codigo_ubigeo VARCHAR(6) COMMENT 'Relación con el catálogo de ubicación geográfica',
    FOREIGN KEY (codigo_ubigeo) REFERENCES ubigeo(codigo_ubigeo)
) COMMENT='Registro maestro de estudiantes';

-- Tabla: Contactos de Emergencia (1 Estudiante puede tener un contacto asignado)
CREATE TABLE contactos_emergencia (
    id_contacto INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Identificador del contacto',
    codigo_estudiante VARCHAR(20) NOT NULL UNIQUE COMMENT 'Código del alumno enlazado',
    nombre_contacto VARCHAR(150) NOT NULL COMMENT 'Nombres y apellidos del familiar/contacto',
    telefono_emergencia VARCHAR(15) NOT NULL COMMENT 'Teléfono de urgencias',
    FOREIGN KEY (codigo_estudiante) REFERENCES estudiantes(codigo_estudiante) ON DELETE CASCADE
) COMMENT='Contactos de emergencia del estudiante';

-- Tabla: Carreras Profesionales
CREATE TABLE carreras (
    codigo_carrera VARCHAR(20) PRIMARY KEY COMMENT 'Código interno de la carrera/programa de estudios',
    nombre_carrera VARCHAR(100) NOT NULL COMMENT 'Nombre oficial (Ej: Diseño y Programación Web)',
    resolucion_ministerial VARCHAR(100) COMMENT 'Número de RM que autoriza el programa'
) COMMENT='Catálogo de carreras del instituto';

-- Tabla: Unidades Didácticas (Cursos según plan curricular)
CREATE TABLE unidades_didacticas (
    codigo_curso VARCHAR(20) PRIMARY KEY COMMENT 'Código de la unidad didáctica (Ej: A, B, UD-101)',
    codigo_carrera VARCHAR(20) NOT NULL COMMENT 'Carrera a la que pertenece el curso',
    nombre_curso VARCHAR(150) NOT NULL COMMENT 'Nombre de la materia/asignatura',
    creditos DECIMAL(4,1) NOT NULL COMMENT 'Valor crediticio de la unidad didáctica',
    semestre_pertenece VARCHAR(20) NOT NULL COMMENT 'Semestre asignado en el plan de estudios',
    FOREIGN KEY (codigo_carrera) REFERENCES carreras(codigo_carrera)
) COMMENT='Catálogo de cursos y asignaturas';

-- ============================================================================
-- TABLAS OPERACIONALES (Matrícula y Nómina)
-- ============================================================================

-- Tabla: Proceso de Matrícula (Cabecera de la ficha individual)
CREATE TABLE matriculas (
    id_matricula INT AUTO_INCREMENT PRIMARY KEY COMMENT 'ID único de la transacción de matrícula',
    codigo_estudiante VARCHAR(20) NOT NULL COMMENT 'Estudiante que realiza la matrícula',
    codigo_carrera VARCHAR(20) NOT NULL COMMENT 'Carrera en la que se matricula',
    periodo_academico VARCHAR(10) NOT NULL COMMENT 'Período académico (Ej: 2025-I, 2026-II)',
    semestre_academico VARCHAR(20) NOT NULL COMMENT 'Semestre lectivo actual (Ej: Quinto, 2°)',
    proceso_fecha DATE NOT NULL COMMENT 'Fecha de registro de la matrícula',
    total_creditos DECIMAL(4,1) NOT NULL COMMENT 'Suma total de créditos inscritos',
    tipo_proceso VARCHAR(50) DEFAULT 'Regular' COMMENT 'Regular, Repitencia, Reingresante',
    CONSTRAINT unq_estudiante_periodo UNIQUE(codigo_estudiante, periodo_academico),
    FOREIGN KEY (codigo_estudiante) REFERENCES estudiantes(codigo_estudiante),
    FOREIGN KEY (codigo_carrera) REFERENCES carreras(codigo_carrera)
) COMMENT='Cabecera de matrículas por periodo';

-- Tabla: Detalle de Matrícula (Cursos inscritos en la ficha individual)
CREATE TABLE detalle_matricula (
    id_detalle INT AUTO_INCREMENT PRIMARY KEY COMMENT 'ID del ítem detallado',
    id_matricula INT NOT NULL COMMENT 'Matrícula a la que pertenece',
    codigo_curso VARCHAR(20) NOT NULL COMMENT 'Unidad didáctica matriculada',
    condicion VARCHAR(50) DEFAULT 'Primera Matricula' COMMENT 'Primera Matricula, 2da Matricula, Repitencia',
    observacion VARCHAR(100) COMMENT 'Anotaciones adicionales sobre la materia',
    FOREIGN KEY (id_matricula) REFERENCES matriculas(id_matricula) ON DELETE CASCADE,
    FOREIGN KEY (codigo_curso) REFERENCES unidades_didacticas(codigo_curso)
) COMMENT='Asignaturas inscritas en cada ficha';

-- Tabla: Nóminas de Matrícula (Cabecera del reporte consolidado oficial por grupo/sección)
CREATE TABLE nominas (
    id_nomina INT AUTO_INCREMENT PRIMARY KEY COMMENT 'ID de la nómina emitida',
    codigo_carrera VARCHAR(20) NOT NULL COMMENT 'Programa de estudios evaluado',
    periodo_academico VARCHAR(10) NOT NULL COMMENT 'Periodo académico del reporte',
    semestre VARCHAR(20) NOT NULL COMMENT 'Semestre del grupo',
    seccion VARCHAR(10) DEFAULT 'Única' COMMENT 'Sección del grupo',
    turno VARCHAR(20) DEFAULT 'Diurno' COMMENT 'Turno de clase',
    fecha_emision DATE NOT NULL COMMENT 'Fecha de cierre y firma de la nómina',
    total_hombres INT DEFAULT 0 COMMENT 'Resumen: Cantidad de varones',
    total_mujeres INT DEFAULT 0 COMMENT 'Resumen: Cantidad de mujeres',
    total_alumnos INT DEFAULT 0 COMMENT 'Resumen: Total de estudiantes matriculados',
    FOREIGN KEY (codigo_carrera) REFERENCES carreras(codigo_carrera)
) COMMENT='Cabecera del consolidado de nómina oficial';

-- Tabla: Detalle de Nómina (Relaciona el consolidado con cada estudiante y sus unidades)
CREATE TABLE detalle_nomina (
    id_detalle_nomina INT AUTO_INCREMENT PRIMARY KEY COMMENT 'ID de fila de la nómina',
    id_nomina INT NOT NULL COMMENT 'Nómina oficial a la que pertenece',
    codigo_estudiante VARCHAR(20) NOT NULL COMMENT 'Estudiante incluido en la lista',
    numero_orden INT NOT NULL COMMENT 'Número correlativo en la nómina (N°)',
    edad_al_momento INT COMMENT 'Edad calculada del estudiante al emitir nómina',
    observacion_nomina VARCHAR(10) DEFAULT 'N' COMMENT 'N = Regular, R1, R2, R3',
    FOREIGN KEY (id_nomina) REFERENCES nominas(id_nomina) ON DELETE CASCADE,
    FOREIGN KEY (codigo_estudiante) REFERENCES estudiantes(codigo_estudiante)
) COMMENT='Lista consolidada de alumnos por nómina';

-- ============================================================================
-- VERIFICACIÓN
-- ============================================================================
SHOW TABLES;