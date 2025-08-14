--
-- MODELO SQLite PARA GESTION DE DATOS EXTRAÍDOS DE SAP
--
-- Text encoding used: UTF-8
--

-- Desactivamos las Foreing keys para poder crear todas las tablas
PRAGMA foreign_keys = off;

-- Se establece el principo de la transacción
BEGIN TRANSACTION;

-- ------------------------------------------------------------------------------------
-- Anticipos solicitados y su estado de tramitación
-- Tables: ANTICIPOS, M_SUBTIPOS_ANTICIPO, M_ESTADOS_ANTICIPO
-- ------------------------------------------------------------------------------------

-- Table: ANTICIPOS
DROP TABLE IF EXISTS ANTICIPOS;
CREATE TABLE IF NOT EXISTS "ANTICIPOS" (
	ntcps_pk INTEGER PRIMARY KEY AUTOINCREMENT,
	empleado TEXT,
	f_solicitud TEXT(100),
	tipo TEXT(200) DEFAULT ('No catalogado') NOT NULL,
	estado TEXT(50) DEFAULT ('No consta') NOT NULL,
	importe INTEGER NOT NULL,
	moneda TEXT(200) DEFAULT ('EUR') NOT NULL,
	CONSTRAINT 'fk_anticipos_empleados'
     FOREIGN KEY ('empleado')
     REFERENCES 'EMPLEADOS' ('CU')
     ON DELETE CASCADE
     ON UPDATE CASCADE,
  CONSTRAINT 'fk_anticipos_estados_tramite'
     FOREIGN KEY ('estado')
     REFERENCES 'M_ESTADOS_ANTICIPO' ('m_estado_anticipo'),
  CONSTRAINT 'fk_anticipos_tipos'
     FOREIGN KEY ('tipo')
     REFERENCES 'M_SUBTIPOS_ANTICIPO' ('m_tipo_anticipo') 
	);

-- Table: M_ESTADOS_ANTICIPO
-- Tabla maestra de estados de tramitación administrativa en que puede encontrarse una solicitud de anticipo
DROP TABLE IF EXISTS M_ESTADOS_ANTICIPO;
CREATE TABLE IF NOT EXISTS "M_ESTADOS_ANTICIPO" (
 m_estado_anticipo_pk INTEGER PRIMARY KEY AUTOINCREMENT,
 m_estado_anticipo TEXT UNIQUE NOT NULL
);
-- Estados identificados hasta el momento en volcados SAP de la tramitación de un anticipo
INSERT INTO M_ESTADOS_ANTICIPO (m_estado_anticipo_pk, m_estado_anticipo) VALUES (0, 'No consta');
INSERT INTO M_ESTADOS_ANTICIPO (m_estado_anticipo_pk, m_estado_anticipo) VALUES (1, 'Solicitado');
INSERT INTO M_ESTADOS_ANTICIPO (m_estado_anticipo_pk, m_estado_anticipo) VALUES (2, 'Autorizado');
INSERT INTO M_ESTADOS_ANTICIPO (m_estado_anticipo_pk, m_estado_anticipo) VALUES (3, 'Autorizado provisional');
INSERT INTO M_ESTADOS_ANTICIPO (m_estado_anticipo_pk, m_estado_anticipo) VALUES (4, 'Denegado');
INSERT INTO M_ESTADOS_ANTICIPO (m_estado_anticipo_pk, m_estado_anticipo) VALUES (5, 'Pagado');
INSERT INTO M_ESTADOS_ANTICIPO (m_estado_anticipo_pk, m_estado_anticipo) VALUES (6, 'En trámite');

-- Table: M_SUBTIPOS_ANTICIPO
-- Tipos de anticipo que se pueden solicitar
DROP TABLE IF EXISTS M_SUBTIPOS_ANTICIPO;
CREATE TABLE IF NOT EXISTS "M_SUBTIPOS_ANTICIPO" (
 m_tipos_anticipo_pk INTEGER PRIMARY KEY AUTOINCREMENT,
 m_tipo_anticipo TEXT UNIQUE NOT NULL
);
-- Ponemos los tipos identificadoshasta ahora
INSERT INTO M_SUBTIPOS_ANTICIPO (m_tipos_anticipo_pk, m_tipo_anticipo) VALUES (0, 'No catalogado');
INSERT INTO M_SUBTIPOS_ANTICIPO (m_tipos_anticipo_pk, m_tipo_anticipo) VALUES (1, 'Nómina Mensual');
INSERT INTO M_SUBTIPOS_ANTICIPO (m_tipos_anticipo_pk, m_tipo_anticipo) VALUES (2, 'Paga Extra');

-- -----------------------------------------------------------------------------------------
-- EMPLEADOS
-- Relación de empleados activos en la organización, así como sus atributos.
-- Table: EMPLEADOS
-- -----------------------------------------------------------------------------------------

DROP TABLE IF EXISTS EMPLEADOS;
CREATE TABLE IF NOT EXISTS "EMPLEADOS" (
	mplds_pk INTEGER PRIMARY KEY AUTOINCREMENT,
	CU TEXT(8) NOT NULL,
	nombre TEXT(200) DEFAULT ('anónimo') NOT NULL,
	NIF TEXT(9) NOT NULL,
	grupo VARCHAR(50) NOT NULL,
	plantilla TEXT(200) DEFAULT ('Sin plantilla'),
	dias INTEGER,
	f_incorporacion TEXT(100) NOT NULL,
	irpf_aplicado REAL,
	irpf_calculado REAL,
	IBAN TEXT(24) DEFAULT ('Sin IBAN'),
	tarj_chaleco TEXT(100) DEFAULT ('Sin tarjeta'),
	solicitar_irpf REAL DEFAULT (0),
	reservado INTEGER DEFAULT 0,
	CONSTRAINT 'fk_empleados_grupos_empleado'
		FOREIGN KEY ('grupo')
		REFERENCES 'M_GRUPOS_EMPLEADO' ('m_grem_code')
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	CONSTRAINT 'fk_empleados_plantillas'
		FOREIGN KEY ('plantilla')
		REFERENCES 'M_PLANTILLA' ('m_plant_code')
);

-- TABLA MAESTRA
-- Tabla maestra de los Grupos en que se clasifican los empleados
-- Table: M_GRUPOS_EMPLEADO
DROP TABLE IF EXISTS M_GRUPOS_EMPLEADO;
CREATE TABLE IF NOT EXISTS "M_GRUPOS_EMPLEADO" (
	m_grem_pk INTEGER PRIMARY KEY AUTOINCREMENT,
	m_grem_code VARCHAR(50),
	m_grem_literal VARCHAR(200)
);
INSERT INTO M_GRUPOS_EMPLEADO (m_grem_pk, m_grem_code, m_grem_literal) VALUES (1, '1', 'Vendedores');
INSERT INTO M_GRUPOS_EMPLEADO (m_grem_pk, m_grem_code, m_grem_literal) VALUES (2, '2', 'No Vendedores');
INSERT INTO M_GRUPOS_EMPLEADO (m_grem_pk, m_grem_code, m_grem_literal) VALUES (3, '3', 'Directivos');
INSERT INTO M_GRUPOS_EMPLEADO (m_grem_pk, m_grem_code, m_grem_literal) VALUES (5, '5', 'Personal No Laboral');

-- TABLA MAESTRA
-- Tabla maestra de plantillas de emplados (días laborables)
-- Table: M_PLANTILLA
DROP TABLE IF EXISTS M_PLANTILLA;
CREATE TABLE IF NOT EXISTS "M_PLANTILLA" (
	m_plant_pk INTEGER PRIMARY KEY AUTOINCREMENT,
	m_plant_code VARCHAR(50) UNIQUE NOT NULL,
	m_plant_template VARCHAR(50),
	m_plant_desc VARCHAR(200)
);
-- Relación de las distintas plantillas teóricas:
INSERT INTO M_PLANTILLA (m_plant_pk, m_plant_code, m_plant_template, m_plant_desc) VALUES (1, 'Tipo 1', 'LLLLLDD', 'Trabaja de lunes a viernes y libra sábado y domingo' );
INSERT INTO M_PLANTILLA (m_plant_pk, m_plant_code, m_plant_template, m_plant_desc) VALUES (2, 'Tipo 2', 'DLLLLLD', 'Trabaja de martes a sábado y libra domingo y lunes' );
INSERT INTO M_PLANTILLA (m_plant_pk, m_plant_code, m_plant_template, m_plant_desc) VALUES (3, 'Tipo 4 A', 'DDLLLLL', 'Trabaja de miércoles a domingo, libra lunes y martes' );
INSERT INTO M_PLANTILLA (m_plant_pk, m_plant_code, m_plant_template, m_plant_desc) VALUES (4, 'Tipo 4 B', 'LDDLLLL', 'Trabaja de jueves a lunes, libra martes y miércoles' );
INSERT INTO M_PLANTILLA (m_plant_pk, m_plant_code, m_plant_template, m_plant_desc) VALUES (5, 'Tipo 4 C', 'LLDDLLL', 'Trabaja de viernes a martes, libra miércoles y jueves' );
-- Relación de las distintas plantillas identificadas en la realidad hasta ahora:
INSERT INTO M_PLANTILLA (m_plant_pk, m_plant_code, m_plant_template, m_plant_desc) VALUES (6, 'Tipo 1 A', 'LLLLLDD', 'Trabaja de lunes a viernes y libra sábado y domingo');
INSERT INTO M_PLANTILLA (m_plant_pk, m_plant_code, m_plant_template, m_plant_desc) VALUES (7, 'Tipo 2 A', 'DLLLLLD', 'Trabaja de martes a sábado y libra domingo y lunes');
INSERT INTO M_PLANTILLA (m_plant_pk, m_plant_code, m_plant_template, m_plant_desc) VALUES (8, 'De 7:45 a 15:00  (36 hrs)', 'XXXXXXX', 'DESCONOCIDO');
INSERT INTO M_PLANTILLA (m_plant_pk, m_plant_code, m_plant_template, m_plant_desc) VALUES (9, 'FLEXIBLE 32,5 horas', 'XXXXXXX', 'DESCONOCIDO');
INSERT INTO M_PLANTILLA (m_plant_pk, m_plant_code, m_plant_template, m_plant_desc) VALUES (10, '09:00/14:00-16:00/18:15', 'XXXXXXX', 'DESCONOCIDO');
-- El personal laboral no tiene plantilla:
INSERT INTO M_PLANTILLA (m_plant_pk, m_plant_code, m_plant_template, m_plant_desc) VALUES (11, 'Sin plantilla', '???????', 'El personal no laboral no tiene plantilla');
-- Vendedores singulares:
INSERT INTO M_PLANTILLA (m_plant_pk, m_plant_code, m_plant_template, m_plant_desc) VALUES (12, 'No vendedor / Vendedor', '???????', 'cosas de SAP');


-- -----------------------------------------------------------------------------------------
-- INCIDENCIAS
-- Table: INCIDENCIAS
-- Se llama 'incidencia' a cuando el trabajador no trabaja o no trabaja toda la jornada.
-- La incidencia puede ser de parcial o de horas, en cuyo caso el día cuenta como 'hábil'.
-- Igualmente en SAP (RRHH) se distingue entre Absentismo y Suplencia.
-- Toda esta tipología se recoge en la tabla.
-- -----------------------------------------------------------------------------------------

DROP TABLE IF EXISTS INCIDENCIAS;
CREATE TABLE IF NOT EXISTS "INCIDENCIAS" (
	incidencia_pk INTEGER PRIMARY KEY AUTOINCREMENT,
	cu VARCHAR(50) NOT NULL,
	causa VARCHAR(200),
	f_desde TEXT(100) NOT NULL,
	f_hasta TEXT(100) NOT NULL,
	CONSTRAINT 'fk_incidencias_causa'
		FOREIGN KEY ('causa')
		REFERENCES 'M_INCIDENCIAS' ('m_incidencias_code'),
	CONSTRAINT 'fk_incidencias_empleados'
		FOREIGN KEY ('cu')
		REFERENCES 'EMPLEADOS' ('CU')
);

-- TABLA MAESTRA
-- Tabla maestra de los tipos de incidencia (causa de la ausencia)
-- En la Organización se denomina "Incidencia" a cuando un vendedor no trabaja.
-- Table: M_INCIDENCIAS
DROP TABLE IF EXISTS M_INCIDENCIAS;
CREATE TABLE IF NOT EXISTS "M_INCIDENCIAS" (
	m_incidencias_pk INTEGER PRIMARY KEY AUTOINCREMENT,
	m_incidencias_code VARCHAR(50)NOT NULL,
	m_incidencias_literal VARCHAR(200) NOT NULL,
	m_incidencias_habil INTEGER DEFAULT (0) NOT NULL,
	m_incidencias_rrhh VARCHAR(50) DEFAULT ('Absentismo')
);

-- Relación de 139 tipos de incidencia identificadas
--
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	1	,	"AA"	,	"VACACIONES AÑO ANTERIOR"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	2	,	"AAP"	,	"ACTUACION ARTISTAS PROMOCION DG"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	3	,	"AB"	,	"FALTA INJUSTIFICADA AL TRABAJO"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	4	,	"AGI"	,	"LICENCIAS RETRIBUIDAS AGENTES IGUALDAD"	,	1	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	5	,	"AP"	,	"LICENCIA ASUNTOS PARTICULARES"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	6	,	"APC"	,	"ASUNTOS PROPIOS C.R.E."	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	7	,	"APM"	,	"MEDIA JORNADA LICENCIA ASUNTOS PARTICUL."	,	1	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	8	,	"AT"	,	"ACCIDENTE DE TRABAJO (IT)"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	9	,	"ATF"	,	"ASISTENCIA A TECNICAS DE FECUNDACION"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	10	,	"BM"	,	"MATERNIDAD"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	11	,	"BMP"	,	"MATERNIDAD A TIEMPO PARCIAL"	,	1	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	12	,	"BP"	,	"PATERNIDAD"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	13	,	"BPP"	,	"PATERNIDAD A TIEMPO PARCIAL"	,	1	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	14	,	"CAJ"	,	"COMPETIC. AJEDREZ FEDC"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	15	,	"CAT"	,	"COMPETIC. ATLETISMO FEDC"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	16	,	"CCI"	,	"COMPETIC. CICLISMO FEDC"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	17	,	"CD"	,	"COMPETICIONES DEPORTIVAS FDC"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	18	,	"CDM"	,	"COMPETIC. DEPORTES MINORITARIOS FEDC"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	19	,	"CDS"	,	"UNA JORNADA DE CREDITO SINDICAL"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	20	,	"CES"	,	"COMPETIC. ESQUI FEDC"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	21	,	"CFD"	,	"CUR.FORM.DIST/CUR.FORM.FUERA JORN.VEND."	,	1	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	22	,	"CFO"	,	"CURSO FORMACION NO VENDEDORES"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	23	,	"CFP"	,	"CURSO FORMACION USUARIOS PERROS GUIA"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	24	,	"CFS"	,	"COMPETIC. FUTBOL SALA FEDC"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	25	,	"CG"	,	"UNA JORNADA ASIST. CONSEJO GENERAL"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	26	,	"CGO"	,	"COMPETIC. GOALBALL FEDC"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	27	,	"CH"	,	"COMPENSACION HORAS EXTRA"	,	1	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	28	,	"CHA"	,	"COMPENSACION HORAS AUTORIZADAS"	,	1	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	29	,	"CHG"	,	"COMPENSACION HORAS GUARDIA"	,	1	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	30	,	"CHS"	,	"CREDITO HORAS SINDICALES"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	31	,	"CIN"	,	"BAJA RETROACTIVA INSS"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	32	,	"CIO"	,	"CITACIÓN ONCE"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	33	,	"CJ"	,	"UNA JORNADA ASIST. COMITES Y JUNTAS"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	34	,	"CJI"	,	"UNA JORNADA ASIST. JUNTAS C.INTERCENTROS"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	35	,	"CJU"	,	"COMPETIC. JUDO FEDC"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	36	,	"CMO"	,	"COMPETIC. MONTAÑISMO FEDC"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	37	,	"CNA"	,	"COMPETIC. NAUTICAS FEDC"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	38	,	"CNT"	,	"COMPETIC. NATACION FEDC"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	39	,	"COV"	,	"Incidencia por COVID-19"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	40	,	"CRI"	,	"CURSO REHABILITACION INTEGRAL"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	41	,	"CS"	,	"COMISION DE SERVICIOS"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	42	,	"CSD"	,	"CESANTIA DIRECTIVOS"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	43	,	"CT"	,	"UNA JORNADA ASIST. CONSEJO TERRITORIAL"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	44	,	"CTO"	,	"COMPETIC. TIRO OLIMPICO FEDC"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	45	,	"CVF"	,	"CURSO FORMACION VENDEDORES FUERA JORND."	,	1	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	46	,	"CVJ"	,	"CURSO FORMACION VENDEDORES DENTRO JORND."	,	1	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	47	,	"DCI"	,	"UNA JORNADA CREDITO SINDICAL C.INTERCENT"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	48	,	"DCL"	,	"DESASTRES CLIMATOLOGICOS"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	49	,	"EAP"	,	"LIC.RETRI. APODERADO ELECC.AUT/GENE/LOCA"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	50	,	"EB"	,	"BAJA POR INCAPACIDAD TEMPORAL (IT)"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	51	,	"EL"	,	"LIBERADO DE TRABAJO ELECCIONES ONCE"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	52	,	"EPP"	,	"EXAMENES PRENATALES Y TECNICAS PREPAR"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	53	,	"EPV"	,	"EVALUADOR PUNTO DE VENTA"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	54	,	"ERT"	,	"REG. TEMP. EMPLEO TOTAL"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	55	,	"FAU"	,	"FIESTA COMUNIDAD AUTONOMA"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	56	,	"FJT"	,	"FALTA JUSTIF.TRABAJO VICT.VIOLENC.GENERO"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	57	,	"FL"	,	"FIESTA LOCAL"	,	0	,	"Suplencia"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	58	,	"FMA"	,	"SITUACION DE FUERZA MAYOR"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	59	,	"FNA"	,	"FIESTA NACIONAL"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	60	,	"FP"	,	"FALTA DE PUNTUALIDAD"	,	1	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	61	,	"FPR"	,	"FIESTA PROVINCIAL"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	62	,	"FX"	,	"DESCANSO POR FESTIVO TRABAJADO"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	63	,	"G3"	,	"ACOMPAÑ.MED.CABECERA HIJOS MEN.14 AÑOS"	,	1	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	64	,	"G4"	,	"CONSULTA MÉDICA SPS TRABAJADOR"	,	1	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	65	,	"G5"	,	"CONSULTA MÉDICA AJENO A SPS TRABAJADOR"	,	1	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	66	,	"G6"	,	"Per.Onco.Rehab.Prev/Ciego"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	67	,	"HAC"	,	"HORAS ASISTENCIA A COMITES Y JUNTAS"	,	1	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	68	,	"HAI"	,	"HORAS ASIST. JUNTAS C.INTERCENTROSS"	,	1	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	69	,	"HFR"	,	"HORAS AGENTE-VENDEDOR COMO FORMADOR"	,	1	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	70	,	"HU"	,	"HUELGA"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	71	,	"HU1"	,	"HUELGA (1 HORA O MENOS)"	,	1	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	72	,	"ICV"	,	"INASISTENCIA CURSO FORMACION VENDEDORES"	,	1	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	73	,	"JE"	,	"MIEMBRO DE JUNTA ELECTORAL ONCE"	,	1	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	74	,	"JUP"	,	"JUBILACION PARCIAL"	,	1	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	75	,	"LAS"	,	"LICENCIA ACTIVIDAD SINDICAL EXTERNA"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	76	,	"LCG"	,	"LIBERADO DE TRABAJO CONSEJO GENERAL"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	77	,	"LCI"	,	"LIBERADO TRAB. REPRES. C.INTERCENTROS"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	78	,	"LCT"	,	"LIBERADO DE TRABAJO CONSEJO TERRITORIAL"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	79	,	"LE"	,	"LICENCIA PARA EXAMENES"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	80	,	"LGP"	,	"LIBERADO C.GENERAL Y PRESID.TERRITORIAL"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	81	,	"LIR"	,	"LICENCIA RETRIBUIDA ELECC. AUT/GENE/LOCA"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	82	,	"LPG"	,	"LICENCIA ASISTENCIA CURSO PERRO GUIA"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	83	,	"LSS"	,	"LICENCIA SIN SUELDO MENOR/IGUAL 15 DIAS"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	84	,	"LTS"	,	"LIBERADO DE TRABAJO ACTIV. SINDICAL"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	85	,	"MC"	,	"MATERNIDAD CONV.COLECT (2 SEMANAS)"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	86	,	"MCJ"	,	"MEDIA JORNADA ASIST. COMITES Y JUNTAS"	,	1	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	87	,	"MCT"	,	"MEDIA JORNADA ASIST. CONSEJO TERRITORIAL"	,	1	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	88	,	"MDI"	,	"MEDIA JORNADA CREDITO SINDICAL C.INTERCE"	,	1	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	89	,	"MDS"	,	"MEDIA JOR. CREDITO SINDICAL"	,	1	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	90	,	"ME"	,	"MIEMBRO DE MESA ELECTORAL"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	91	,	"MLA"	,	"MIEMBRO DE MESA ELECTORAL AUT/GENE/LOCA"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	92	,	"MMO"	,	"MIEMBRO DE MESA ELECTORAL ONCE"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	93	,	"MRC"	,	"MEDIA LICENCIA RETRIBUIDA POR CANDIDATUR"	,	1	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	94	,	"MRE"	,	"MEDIA LICENCIA RETRIBUIDA ELECTOR ONCE"	,	1	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	95	,	"MRO"	,	"LICENCIA RETRIB. CANDIDATURA ONCE"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	96	,	"NFL"	,	"NO ENTREGA DE PRODUCTO POR FALTA LIQUID."	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	97	,	"OF"	,	"OLVIDO FICHAR"	,	1	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	98	,	"OV"	,	"ORDEN DE VIAJE"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	99	,	"PAA"	,	"PARTICIPACION ACTIVIDADES AREA COMERCIAL"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	100	,	"PAI"	,	"PERIODO EFECTOS ALTA INSS/CONOC.EMPRESA"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	101	,	"PAM"	,	"PARTIC. ACTUACIONES MUSICALES DG"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	102	,	"PB1"	,	"PERMISO NACIMIENTO IGUAL PROVINCIA"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	103	,	"PB2"	,	"PERMISO NACIMIENTO OTRA PROVINCIA"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	104	,	"PCT"	,	"LIB. PARCIAL VICEPRESID.CONSEJO TERRT."	,	1	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	105	,	"PC1"	,	"PERMISO ENF. GRAVE FAMILIAR IGUAL PROV."	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	106	,	"PC2"	,	"PERMISO ENF. GRAVE FAMILIAR OTRA PROV."	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	107	,	"PC3"	,	"PERMISO INGRESO HOSPIT. HIJOS < 12 AÑOS"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	108	,	"PD1"	,	"PERMISO FALLEC.FAM. 2º GRADO IGUAL PROV."	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	109	,	"PD2"	,	"PERMISO FALLEC.FAM. 2º GRADO OTRA PROV."	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	110	,	"PD3"	,	"PERMISO FALLEC.FAM. 1º GRADO IGUAL PROV."	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	111	,	"PD4"	,	"PERMISO FALLEC.FAM. 1º GRADO OTRA PROV."	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	112	,	"PE1"	,	"Permiso especial antigüedad"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	113	,	"PEG"	,	"Asist.Veterin.Perro-guia"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	114	,	"PME"	,	"PARTIC. MUESTRA ESTATAL DG"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	115	,	"PRE"	,	"PERMISO RETRIBUIDO ESPECIAL"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	116	,	"PRI"	,	"Permiso promoción interna"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	117	,	"PTE"	,	"PARTIC. REPRESENTACIONES TEATRALES DG"	,	1	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	118	,	"P1"	,	"MATRIMONIO/PAREJA DE HECHO"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	119	,	"P10"	,	"AUSENCIA JUSTIFICADA"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	120	,	"P15"	,	"Permiso retrib.esp.15 años"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	121	,	"P5"	,	"TRASLADO DE DOMICILIO"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	122	,	"P7"	,	"DEBER PUBLICO"	,	1	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	123	,	"P8"	,	"LACTANCIA"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	124	,	"REF"	,	"LIC.RETRI. REFERENTE CONSEJO TERRITORIAL"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	125	,	"RM"	,	"RECONOCIMIENTO MEDICO"	,	1	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	126	,	"SA"	,	"SANCION DISCIPLINARIA"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	127	,	"SCS"	,	"SUSPENSION CAUTELAR DE EMPLEO/SUELDO"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	128	,	"SD"	,	"DESCANSO SEMANAL"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	129	,	"TD"	,	"DESCANSO TRABAJADO"	,	1	,	"Suplencia"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	130	,	"TF"	,	"Trabajo en día festivo"	,	0	,	"Suplencia"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	131	,	"VA"	,	"VACACIONES"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	132	,	"VAC"	,	"VACACIONES C.R.E."	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	133	,	"VC"	,	"VACACIONES CONCEDIDAS"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	134	,	"VF"	,	"VACACIONES PLANIFICADAS"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	135	,	"VI"	,	"VACACIONES INTERRUMPIDAS (IT HOSPITAL)"	,	0	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	136	,	"XF"	,	"FESTIVO TRABAJADO"	,	1	,	"Absentismo"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	137	,	"ZD"	,	"DESCANSO POR DIA DESCANSO TRABAJADO"	,	0	,	"Suplencia"	);
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	138	,	"ZF"	,	"Descanso por TF"	,	0	,	"Suplencia"	);
-- Valores que han ido apareciendo y no estaban inventariados:
INSERT INTO M_INCIDENCIAS (m_incidencias_pk, m_incidencias_code, m_incidencias_literal, m_incidencias_habil, m_incidencias_rrhh) VALUES (	139	,	"CHE"	,	"Compensación horas exceso"	,	1	,	"Absentismo"	);



-- Commit de la transacción -----
COMMIT TRANSACTION;

-- Activamos las Foreing keys de nuevo para que se apliquen la restricciones de integridad
PRAGMA foreign_keys = on;
