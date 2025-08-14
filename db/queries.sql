--
-- TABLA FILE_METADATA DE LA BASE DE DATOS  SQLite DONDE
-- SE GUARDAN LAS QUERIES QUE OBTIENEN LOS DATOS PARA LOS
-- TESTS AUTOMÁTICOS.
--
-- Text encoding used: UTF-8
--

-- Desactivamos las Foreing keys para poder crear todas las tablas
PRAGMA foreign_keys = off;

-- Se establece el principo de la transacción
BEGIN TRANSACTION;

-- ------------------------------------------------------------------------------------
-- Table: FILE_METADATA
-- Guarda toda la información relativa a cada fichero de test.
-- Dichos ficheros se podrán generar a partir de dichos datos.
-- Asi mismo, existe la posibilidad de explotar estos datos para otras tareas.
-- ------------------------------------------------------------------------------------
DROP TABLE IF EXISTS FILE_METADATA;
CREATE TABLE IF NOT EXISTS "FILE_METADATA" (
	fm_pk INTEGER PRIMARY KEY AUTOINCREMENT,
	fm_literal TEXT (50),
	fm_title TEXT (100),
	fm_fichero TEXT (300),
	fm_datos TEXT (300),
	fm_query TEXT (1000),
	fm_criterio TEXT (600),
	fm_obs TEXT (600),
	fm_activo INTEGER DEFAULT (1)
	);

------------------------------------------------------------------------

INSERT INTO FILE_METADATA (fm_pk, fm_literal, fm_title, fm_fichero, fm_datos, fm_query, fm_criterio, fm_obs, fm_activo)
VALUES (
1, 
"CONINC-01",
"Consulta de las incidencias de un empleado que tenga incidencias en el año actual y el anterior pero no tenga para el próximo",
"CPA-WEB-CONINC-01-Oscar-Gestiona-Consultas-Consulta de incidencias.txt",
"- NIF de un empleado adecuado
- Clave Portal
- Clave Gestiona
",
"Un empleado que tenga incidencias en el año actual y el anterior pero no tenga para el próximo.
(esto hay que descomponerlo en varios tests)",
"
SELECT e.NIF FROM EMPLEADOS e WHERE
e.CU IN (
  SELECT e.CU
  FROM EMPLEADOS e , INCIDENCIAS i 
  WHERE
   -- Usuario QA
   e.reservado = 0
   AND -- Join con incidencias
   e.CU = i.cu 
   AND 
   -- Tiene incidencias en año anterior
   strftime('%Y', i.f_desde) = strftime('%Y', 'now', '-1 year')
)
AND e.CU IN (
   SELECT e.CU 
   FROM EMPLEADOS e , INCIDENCIAS i 
   WHERE
   -- Join con incidencias
   e.CU = i.cu 
   AND 
   -- Tiene incidencias en año actual
   strftime('%Y', i.f_desde) = strftime('%Y', 'now', '+0 year')
)
AND e.CU NOT IN (
   SELECT e.CU
   FROM EMPLEADOS e , INCIDENCIAS i 
   WHERE
   -- Join con incidencias
   e.CU = i.cu 
   AND 
   -- Tiene incidencias en año próximo
   strftime('%Y', i.f_hasta) = strftime('%Y', 'now', '+1 year')
)
-- Elegimos uno al azar
ORDER BY RANDOM() LIMIT 1;
",
"Originalmente concebido como test manual, este caso tan complejo deberá de descomponerse en sus tres casuísticas.
Podría no poder ejecutarse si se ejecuta a comienzo de año o en un momento en el que no hay incidencia en el año en curso.
El empleado utilizado NO se quema, es reutilizable para ejecuciones sucesivas.
Podría fallar si se ejecuta en un momento en el que el sistema tiene incidencias del año que viene (p ej si se hace una copia de producción a aceptación en los meses de nov-dic y se ejecuta la batería automatizada en aceptación antes de fin de año, después de la copia).",
0
);

------------------------------------------------------------------------

INSERT INTO FILE_METADATA (fm_pk, fm_literal, fm_title, fm_fichero, fm_datos, fm_query, fm_criterio, fm_obs, fm_activo)
VALUES (
2, 
"CONCHR-01",
"Consulta del certificado de Haberes y Retenciones del vendedor",
"CPA-WEB-CONCHR-01-Gestiona-Consultas-Consulta-Certificado-Haberes-Retenciones.txt",
"- NIF de un vendedor con antigüedad.
- Clave Portal
- Clave Gestiona
",
"Vendedores con certificado de haberes y retenciones del año fiscal actual y anterior.",
"
SELECT e.NIF 
FROM EMPLEADOS e 
WHERE 
-- Usuario QA
e.reservado = 0 
AND 
-- Antigüedad superior a 4 años.
(e.f_incorporacion < DATE('now', '-4 years') )
AND 
-- Vendedor
(e.grupo = 1)
-- Elegimos uno al azar
ORDER BY RANDOM() LIMIT 1;
",
"[Problema] No disponemos de información de certificados de haberes y retenciones.
¿Se generan siempre por defecto para todos?
Lo que hacemos es buscar vendedores con una antigüedad superior a cuatro años y confiar que baste con eso.

¯\_(*`︵´*)_/¯
",
1
);

------------------------------------------------------------------------

INSERT INTO FILE_METADATA (fm_pk, fm_literal, fm_title, fm_fichero, fm_datos, fm_query, fm_criterio, fm_obs, fm_activo)
VALUES (
3, 
"CONINC-01",
"Consulta de las incidencias de un empleado con incidencias en el año actual",
"CPA-WEB-CONINC-01-Gestiona-Consultas-Consulta de incidencias.txt",
"- NIF de un empleado adecuado
- Clave Portal
- Clave Gestiona
",
"Un empleado que tenga incidencias en el año actual.",
"
SELECT e.NIF FROM EMPLEADOS e, INCIDENCIAS i 
WHERE
   -- Usuario QA
   e.reservado = 0
   AND 
   -- Join con incidencias
   e.CU = i.cu 
   AND 
   -- Tiene incidencias en año actual
   strftime('%Y', i.f_desde) = strftime('%Y', 'now', '+0 year')
   -- No está en la lista negra
   AND e.reservado <> 1
-- Elegimos uno al azar
ORDER BY RANDOM() LIMIT 1;
",
"Podría no poder ejecutarse si se ejecuta a comienzo de año o en un momento en el que no hay incidencia en el año en curso.
El empleado utilizado NO se quema, es reutilizable para las siguientes baterías.
Podría fallar si se ejecuta en un momento en el que el sistema tiene incidencias del año que viene (p ej si se hace una copia de producción a aceptación en los meses de nov-dic y se ejecuta la batería automatizada en aceptación antes de fin de año, después de la copia).",
1
);

------------------------------------------------------------------------

INSERT INTO FILE_METADATA (fm_pk, fm_literal, fm_title, fm_fichero, fm_datos, fm_query, fm_criterio, fm_obs, fm_activo)
VALUES (
4, 
"CONINC-02",
"Consulta de las incidencias de un empleado con incidencias en el año pasado",
"CPA-WEB-CONINC-02-Gestiona-Consultas-Consulta de incidencias.txt",
"- NIF de un empleado adecuado
- Clave Portal
- Clave Gestiona
",
"Un empleado que tenga incidencias en el año pasado.",
"
SELECT e.NIF FROM EMPLEADOS e, INCIDENCIAS i 
WHERE
   -- Usuario QA
   e.reservado = 0
   AND
   -- Join con incidencias
   e.CU = i.cu 
   AND 
   -- Tiene incidencias en año pasado
   strftime('%Y', i.f_desde) = strftime('%Y', 'now', '-1 year')
   -- que no esté en la lista negra
   AND e.reservado <> 1
-- Elegimos uno al azar
ORDER BY RANDOM() LIMIT 1;
",
"El empleado utilizado NO se quema, es reutilizable si se quiere volver a ejecutar.",
1
);

------------------------------------------------------------------------

INSERT INTO FILE_METADATA (fm_pk, fm_literal, fm_title, fm_fichero, fm_datos, fm_query, fm_criterio, fm_obs, fm_activo)
VALUES (
5, 
"CONINC-03",
"Consulta de las incidencias de un empleado sin incidencias en el año próximo",
"CPA-WEB-CONINC-03-Gestiona-Consultas-Consulta de incidencias.txt",
"- NIF de un empleado adecuado
- Clave Portal
- Clave Gestiona
",
"Un empleado que no tenga incidencias en el año próximo.",
"
SELECT e.NIF, i.f_desde FROM EMPLEADOS e, INCIDENCIAS i 
WHERE
   -- Usuario QA
   e.reservado = 0
   AND
   -- Join con incidencias
   e.CU = i.cu 
   -- No en lista negra
   AND e.reservado <> 1
   -- No tiene incidencias el año que viene
   AND e.CU NOT IN (
	   SELECT e.CU
	   FROM EMPLEADOS e , INCIDENCIAS i 
	   WHERE
	   -- Join con incidencias
	   e.CU = i.cu 
	   AND 
	   -- Tiene incidencias en año próximo
	   strftime('%Y', i.f_hasta) = strftime('%Y', 'now', '+1 year')
	)
-- Elegimos uno al azar
ORDER BY RANDOM() LIMIT 1;
",
"El empleado utilizado NO se quema, es reutilizable si se quiere volver a ejecutar.",
1
);

------------------------------------------------------------------------

INSERT INTO FILE_METADATA (fm_pk, fm_literal, fm_title, fm_fichero, fm_datos, fm_query, fm_criterio, fm_obs, fm_activo)
VALUES (
6, 
"TRAPESPANT-01",
"Solicitar un permiso retribuído especial por antigüedad (PE1) para el lunes próximo",
"CPA-WEB-TRAPESPANT-01-Gestiona-Tramites-Permiso-Retribuido-Especial-Antiguedad-(11-22 años).txt",
"- NIF de un empleado con antigüedad superiora 11 años
- Clave Portal
- Clave Gestiona
- Fecha (lunes próximo sin incidencias)
",
"(Ver apartado OBSERVACIONES)",
"
SELECT e.NIF , date('now', 'weekday 1', '+7 days')
FROM EMPLEADOS e 
WHERE
    -- Es vendedor
    e.grupo = 1
    AND 
    -- Normalmente trabaja los lunes
    e.plantilla = 'Tipo 1 A'
    AND 
    -- Antigüedad de más de 11 años
    (e.f_incorporacion < DATE('NOW', '-11 years'))
    AND 
    -- Usuario QA con acceso habilitado
    e.reservado = 0
    -- Este año no ha pedido una PE1
	AND e.CU NOT IN ( 
		SELECT i.cu from INCIDENCIAS i 
        WHERE strftime('%Y', i.f_hasta) = strftime('%Y', 'now')
        AND i.causa = 'PE1'
	    )  
    -- Próximo lunes no debe tener incidencia registrada
	AND e.CU NOT IN ( 
		SELECT DISTINCT inci.cu FROM INCIDENCIAS inci 
	    WHERE date('now', 'weekday 1', '+7 days') BETWEEN inci.f_desde AND inci.f_hasta    
	    )    
-- Elegimos uno al azar
ORDER BY RANDOM() LIMIT 1;
",
"Se trata de buscar el NIF de un empleado vendedor con antigüedad superior a 11 años, y hacerle solicitar un PE1 para el lunes que viene.
Este tipo de permiso viene regulado por el artículo 34 del vigente convenio colectivo.
Si tiene más de 11 años le corresponde un día de permiso de este tipo anual.
Si tiene más de 12 años le corresponderían 2 días (uno por semeste).

Restricciones:
1. No puede haber registrado ya una solicitud de este tipo ('PE1-Permiso especial antigüedad') en el año en curso 
2. El lunes tiene que ser laborable para él (aseguramos que sea un vendedor con plantilla 'Tipo 1A')
3. No tiene que tener ninguna otra incidencia prevista para el próximo lunes
",
1
);

------------------------------------------------------------------------

INSERT INTO FILE_METADATA (fm_pk, fm_literal, fm_title, fm_fichero, fm_datos, fm_query, fm_criterio, fm_obs, fm_activo)
VALUES (
7, 
"NOMINA-01",
"Consultar y descargar nóminas",
"CPA-WEB-NOMINA-01-Gestiona-Nomina.txt",
"- NIF de un empleado con nóminas como las requeridas
- Clave Portal
- Clave Gestiona
",
"Buscar el NIF de un empleado vendedor/no vendedor usuario tenga disponibles
nominas en los 2 últimos años, incluidas una nómina mensual y liquidación anual
en el último año, y una paga extra en el último mes del penúltimo año",
"
SELECT e.NIF as 'NIF' 
FROM EMPLEADOS e 
WHERE
-- Antigüedad de más de 4 años
(e.f_incorporacion < DATE('NOW', '-4 years'))
AND 
-- Vendedor
(e.grupo = 1)
-- Que no esté en la lista negra
AND e.reservado <> 1
-- Elegimos uno al azar
ORDER BY RANDOM() 
LIMIT 1;
",
"
NO tenemos información sobre nóminas del empleado para atender las tres condiciones siguientes:
1 - 'Que el usuario tenga disponible nóminas en los 2 últimos años': esto va a tener que suponerse para empleados con antigüedad de más de dos años.
2 - '..incluidas una nómina mensual y liquidación anual en el último año': ¿liquidación anual?
3 - '..y una paga extra en el último mes del penúltimo año.': confiar en que el empleado tenga extra de Navidad (14 pagas).

¯\_(*̀ ︵ ́*)_/¯
",
1
);

------------------------------------------------------------------------

INSERT INTO FILE_METADATA (fm_pk, fm_literal, fm_title, fm_fichero, fm_datos, fm_query, fm_criterio, fm_obs, fm_activo)
VALUES (
8,
"TRAANTNOM-01",
"Dar de alta la solicitud de un anticipo de nómina mensual",
"CPA-WEB-TRAANTNOM-01-Gestiona-Tramites-Solicitud-Anticipo-Nomina.txt",
"- NIF de un empleado que no ha solicitado anticipo este mes
- Clave Portal
- Clave Gestiona
",
"Empleado vendedor/no vendedor que no tenga solicitado anticipo tipo nómina mensual en el mes en curso.",
"
SELECT DISTINCT e.NIF 
FROM ANTICIPOS a , EMPLEADOS e
WHERE a.empleado = e.CU
AND 
-- Usuario QA que accede al Portal
    e.reservado = 0
AND 
-- Que no tenga una solicitud de ese tipo para este mes
   a.empleado NOT IN ( 
   SELECT an.empleado FROM ANTICIPOS an 
   WHERE strftime('%Y-%m', an.f_solicitud) = strftime('%Y-%m', 'now') 
   AND an.tipo = 1 
)
-- Elegimos uno al azar
ORDER BY RANDOM() LIMIT 1;
",
"Empleado vendedor/no vendedor que no tenga solicitado anticipos de nómina en el mes en curso (nómina mensual).
Para el caso de otro test en el que el tipo de anticipo sea 'paga extra' consideraríamos todo el semestre en curso.
En la tabla ANTICIPOS tenemos esa información de anticipos de nómina mensual que tenemos identificado como de tipo 1.
El empleado utilizado se quema, no es reutilizable para la siguiente batería en el mismo período de devengo de la nómina correspondiente.",
1
);

------------------------------------------------------------------------

INSERT INTO FILE_METADATA (fm_pk, fm_literal, fm_title, fm_fichero, fm_datos, fm_query, fm_criterio, fm_obs, fm_activo)
VALUES (
9,
"TRASOLPRETR-01",
"Solicitud de permiso por asistencia a consulta médica (incidencia tipo G5)",
"CPA-WEB-TRASOLPRETR-01-Gestiona-Tramites-Solicitud-Permisos-Retribuidos.txt",
"- NIF de un vendedor
- Clave Portal
- Clave Gestiona
- Fecha del permiso a solicitar (próximo lunes)
",
"Buscamos un vendedor para el que el próximo lunes sea laborable y sin incidencia prevista.",
"
SELECT DISTINCT e.NIF, date('now', 'weekday 1') as 'Fecha G5'
from EMPLEADOS e , INCIDENCIAS i 
WHERE 
	-- Es un vendedor 
	e.grupo = 1
	AND 
	-- Trabaja los lunes
	e.plantilla = 'Tipo 1 A' 
	AND 
	-- Es un usuario para QA habilitado en el Portal
	e.reservado = 0 
	AND 
	-- Hacemos el Join
	e.CU = i.cu 	
	-- No está entre los que tienen incidencias el lunes próximo  
    AND e.CU NOT IN (
    SELECT inci.cu FROM INCIDENCIAS inci WHERE 
        date('now', 'weekday 1') BETWEEN inci.f_desde AND inci.f_hasta
    )
-- Elegimos uno al azar
ORDER BY RANDOM() LIMIT 1;
",
"El día elegido debe acomodarse a su plantilla calendario y no tener incidencia registrada prevista.
El día será siempre el lunes siguiente, para lo que se elegirá un vendedor con plantilla 'Tipo 1 A', que trabajan los lunes.",
1
);

------------------------------------------------------------------------

INSERT INTO FILE_METADATA (fm_pk, fm_literal, fm_title, fm_fichero, fm_datos, fm_query, fm_criterio, fm_obs, fm_activo)
VALUES (
10,
"TRASOLMODPERS-01",
"Modificar los datos identificactivos de la tarjeta",
"CPA-WEB-TRASOLMODPERS-01-Gestiona-Tramites-Solicitud-Modificacion-Datos-Identificativos-Contacto.txt",
"- NIF de un vendedor
- Clave Portal
- Clave Gestiona
",
"Empleado (vendedor) que ya tuviese nombre en la tarjeta.",
"
SELECT e.NIF FROM EMPLEADOS e 
-- Es vendedor
WHERE e.grupo = 1 
-- Usa tarjeta chaleco
AND e.tarj_chaleco <> '' 
-- Usuario para QA habilitado en el Portal
AND	e.reservado = 0 
-- Elegimos uno al azar
ORDER BY RANDOM() LIMIT 1;
",
"Elegimos un vendedor que ya tuviese nombre en la tarjeta.",
1
);

-----------------------------------------------------------------------

INSERT INTO FILE_METADATA (fm_pk, fm_literal, fm_title, fm_fichero, fm_datos, fm_query, fm_criterio, fm_obs, fm_activo)
VALUES (
11,
"TRASOLVARIRPF-01",
"Solicitud de variación del porcentaje de retención de IRPF en nómina",
"CPA-WEB-TRASOLVARIRPF-01-Gestiona-Tramites-Solicitud-Variacion-Porcentaje-IRPF.txt",
"- NIF de un vendedor
- Clave Portal
- Clave Gestiona
- Porcentaje de referencia para el cambio (deberá de ser mayor)
",
"NIF de vendedor que pueda solicitar cambio de retención IRPF",
"
SELECT e.NIF, CAST(e.solicitar_irpf AS TEXT) AS irpf 
FROM EMPLEADOS e
WHERE 
-- Porcentaje actual de referencia
e.solicitar_irpf <> 0
AND -- Vendedor
e.grupo = 1 
AND -- Usuario QA habilitado en el Portal
e.reservado = 0  
-- Elegimos uno al azar
ORDER BY RANDOM() LIMIT 1;
",
"Existe una lógica nada intuitiva con la que podemos saber si una solicitud es viable atendiendo a la restricción de que 'Sólo puede solicitar una modificación de %IRPF al año'.
Es decir, podemos saber si éste año ya se le ha implementado ese cambio hasta el mes en curso (si los datos están actualizados).
La mala suerte sería que justo en éste momento existiese esa petición en trámite en el Sistema para el usuario elegido. Eso haría fallar el test con un falso positivo.
Otra posibilidad de error sería que el empleado TUVIESE INFORMADA UNA PENSIÓN COMPENSATORIA O DE ALIMENTOS. Actualmente no disponemos de ese dato y el test fallaría.

¯\_(*̀ ﹏ ́*)_/¯
",
1
);

-----------------------------------------------------------------------

INSERT INTO FILE_METADATA (fm_pk, fm_literal, fm_title, fm_fichero, fm_datos, fm_query, fm_criterio, fm_obs, fm_activo)
VALUES (
12,
"TRANOTSOL-01",
"Cambia la actual política de notificación y verifica que se ha registrado la solicitud de ese cambio",
"CPA-WEB-TRANOTSOL-01-Gestiona-Tramites-Notificacion-Solicitudes.txt",
"- NIF de empleado activo cualquiera
- Clave Portal
- Clave Gestiona
",
"Buscar el NIF de un empleado vendedor/no vendedor.",
"
SELECT e.NIF FROM EMPLEADOS e 
WHERE 
-- Usuario QA habilitado en el Portal
   e.reservado = 0
-- Elegimos uno al azar
ORDER BY RANDOM() LIMIT 1;
",
"Todos los empleados están activos, todos valen.
Menos los de la lista negra y los que no tengan el acceso configurado para QA.",
1
);

-----------------------------------------------------------------------

INSERT INTO FILE_METADATA (fm_pk, fm_literal, fm_title, fm_fichero, fm_datos, fm_query, fm_criterio, fm_obs, fm_activo)
VALUES (
13,
"TRASOLECXD-01",
"Solicitud de Excedencia",
"CPA-WEB-TRASOLECXD-01-Gestiona-Tramites-Solicitud-Excedencias.txt",
"- Clave Portal
- Clave Gestiona
- NIF de empleado
- Fecha inicio de la excedencia
- Fecha fin de la excedencia
",
"NIF de un empleado y periodo de la excedencia en el que no tenga incidencias previas.",
"
SELECT e.NIF, date('now', '+1 month') as 'desde', date('now', '+3 month') as 'hasta' 
FROM EMPLEADOS e , INCIDENCIAS i 
WHERE 
  -- No está en la lista negra
  e.reservado <> 1 
  AND 
  -- Hacemos el Join
  e.CU = i.cu 
  -- No está entre los que tienen incidencias en ese periodo  
  AND e.CU NOT IN (
    SELECT inci.cu FROM INCIDENCIAS inci WHERE 
        inci.f_hasta >= date('now', '+1 month')
    )
-- Elegimos uno al azar
ORDER BY RANDOM() LIMIT 1;
",
"En la tabla INCIDENCIAS no aparece ninguna 'Excedencia'.
Es decir, no tenemos el dato de las excedencias pedidas y su periodo
(un empleado que no esté de excedencia es cualquiera que esté activo, pero no sabemos si la tiene pedida para mañana, en cuyo caso el sistema no permitiría la solicitud y fallaría el test)
¯\_(*̀ ︵ ́*)_/¯",
1
);

-----------------------------------------------------------------------

INSERT INTO FILE_METADATA (fm_pk, fm_literal, fm_title, fm_fichero, fm_datos, fm_query, fm_criterio, fm_obs, fm_activo)
VALUES (
14,
"TRASOLAAPP-01",
"Solicitar licencia de asuntos propios (incidencia tipo AP)",
"CPA-WEB-TRASOLAAPP-01-Gestiona-Tramites-Solicitud-Asuntos-Particulares.txt",
"- NIF de un vendedor adecuado
- Clave Portal
- Clave Gestiona
- Fecha del día a solicitar para asuntos propios
",
"Se trata de buscar un empleado que pueda pedirse un día de asuntos propios en una fecha futura dada.

Se cuenta con seis días de permiso por Asuntos Particulares.
Se contemplan en el artículo 36 del XVII Convenio Colectivo, que establece para todos los trabajadores y trabajadoras la posibilidad de disfrutar de hasta seis días de licencia retribuida cada año natural, de forma proporcional a su jornada semanal, y respetando siempre las necesidades del servicio. Podrán ser disfrutados en jornadas completas o en forma de medias jornadas. En todo caso, unicamente uno de ellos podrá acumularse a las vacaciones anuales.
Nota Importante: La cumplimentación y envío de la solicitud no supone su aprobación, solo su entrada en el circuito de validación. La ONCE revisará si cumple los requerimientos y procederá a su aprobación o a su denegación.
Es responsabilidad del trabajador comprobar en PortalONCE el estado de la solicitud.
Se aconseja activar en la opción “Notificación de solicitudes” un medio para recibir información inmediata del estado de su solicitud (correo electrónico, SMS y/o notificación en el móvil).",
"
SELECT DISTINCT e.NIF , date('now', 'weekday 1', '+7 days') 
from  EMPLEADOS e , INCIDENCIAS i
WHERE 
    -- Es vendedor
    e.grupo = 1
AND -- Trabaja los lunes
    e.plantilla = 'Tipo 1 A'
AND -- Join de las tablas
    e.CU = i.cu
AND -- Usuario QA habilitado
    e.reservado = 0
AND -- Ese próximo lunes no debe tener incidencia registrada 
    date('now', 'weekday 1', '+7 days') NOT BETWEEN i.f_desde AND i.f_hasta
AND -- El empleado tiene menos de 5 solicitudes AP
    e.CU IN (
    SELECT inci.cu
    FROM INCIDENCIAS inci 
    WHERE inci.causa = 'AP' 
    GROUP BY inci.cu 
    HAVING COUNT(*) < 5
    )
-- Elegimos uno al azar
ORDER BY RANDOM() LIMIT 1;
",
"Ese día futuro debe cumplir:
-- 1. que no sea festivo, 
-- 2. que se ajuste a su calendario, 
-- 3. que no tenga ninguna otra incidencia ese día y
-- 4. que le queden días para pedir (tiene un máximo de 6 al año)
--
-- Así que elegiremos un vendedor que trabaje el lunes que viene y que no tenga ya una incidencia ese día.
-- Y que no tenga más de 5 solicitudes tipo AP ya pedidos este año.",
1
);

-----------------------------------------------------------------------

INSERT INTO FILE_METADATA (fm_pk, fm_literal, fm_title, fm_fichero, fm_datos, fm_query, fm_criterio, fm_obs, fm_activo)
VALUES (
15,
"TRASOLLIC-01",
"SOLICITUD DE LICENCIA: Licencia sin sueldo no superior a 15 días (LSS)",
"CPA-WEB-TRASOLLIC-01-Gestiona-Tramites-Solicitud-Licencias.txt",
"- Clave Portal
- Clave Gestiona
- NIF de un vendedor activo
- Fecha inicio de la licencia LSS (mañana)
- Fecha fin de la licencia LSS (duración de 7 días)
",
"NIF de un vendedor y periodo de 7 días a partir de mañana sin incidencias previas en esos días.",
"
SELECT e.NIF, date('now', '+1 day') as 'desde', date('now', '+8 days') as 'hasta' 
FROM EMPLEADOS e , INCIDENCIAS i 
WHERE 
	-- Es un vendedor 
	e.grupo = 1
	AND 
	-- y trabaja el lunes
	e.plantilla = 'Tipo 1 A' 
	AND 
	-- Es un usuario QA habilitado
	e.reservado = 0 
	AND 
	-- Hacemos el Join
	e.CU = i.cu 
	AND 
	-- No está entre los que tienen incidencias en ese periodo
	e.CU NOT IN (
		SELECT inci.cu FROM INCIDENCIAS inci WHERE 
		     inci.f_hasta >= date('now', '+9 days')
	) 
-- Elegimos uno al azar
ORDER BY RANDOM() LIMIT 1;
",
"Hay festivos en el intervalo de días, pero eso lo admite el sistema",
1
);

-----------------------------------------------------------------------

INSERT INTO FILE_METADATA (fm_pk, fm_literal, fm_title, fm_fichero, fm_datos, fm_query, fm_criterio, fm_obs, fm_activo)
VALUES (
16,
"PLAINLOGIN-01",
"Distintas modalidades de acceso al portal y a Gestiona.
01 - Acceso básico al portal",
"CPA-WEB-PLAINLOGIN-01-Login.txt",
"- NIF empleado cualquiera
- Clave Portal
- Clave Gestiona ¿?
",
"NIF de cualquier empleado que no esté en la lista negra y que tenga la pass configurada.",
"
SELECT e.NIF FROM EMPLEADOS e 
WHERE 
-- Usuario QA 
   e.reservado = 0
-- Elegimos uno al azar
ORDER BY RANDOM() LIMIT 1;
",
"",
1
);

-----------------------------------------------------------------------

INSERT INTO FILE_METADATA (fm_pk, fm_literal, fm_title, fm_fichero, fm_datos, fm_query, fm_criterio, fm_obs, fm_activo)
VALUES (
17,
"PLAINLOGIN-02",
"Distintas modalidades de acceso al portal y a Gestiona.
02 - Acceso a gestiona desde el Portal",
"CPA-WEB-PLAINLOGIN-02-Login.txt",
"- NIF empleado cualquiera
- Clave Portal
- Clave Gestiona
",
"NIF de cualquier empleado disponible.",
"
SELECT e.NIF FROM EMPLEADOS e 
WHERE 
-- Usuario QA 
   e.reservado = 0
-- Elegimos uno al azar
ORDER BY RANDOM() LIMIT 1;
",
"",
1
);

-----------------------------------------------------------------------

INSERT INTO FILE_METADATA (fm_pk, fm_literal, fm_title, fm_fichero, fm_datos, fm_query, fm_criterio, fm_obs, fm_activo)
VALUES (
18,
"PLAINLOGIN-03",
"Distintas modalidades de acceso al portal y a Gestiona.
03 - Acceso a gestiona mediante deep-linking",
"CPA-WEB-PLAINLOGIN-03-Login.txt",
"- NIF empleado cualquiera
- Clave Portal ¿?
- Clave Gestiona
",
"NIF de cualquier empleado (que no esté en la lista negra).",
"
SELECT e.NIF FROM EMPLEADOS e 
WHERE 
-- Usuario QA 
   e.reservado = 0
-- Elegimos uno al azar
ORDER BY RANDOM() LIMIT 1;
",
"",
1
);

-----------------------------------------------------------------------

INSERT INTO FILE_METADATA (fm_pk, fm_literal, fm_title, fm_fichero, fm_datos, fm_query, fm_criterio, fm_obs, fm_activo)
VALUES (
19,
"PLAINMENU-01",
"Valida las opciones de menú del Portal del empleado.",
"CPA-WEB-PLAINMENU-01-Menu.txt",
"- NIF empleado cualquiera
- Clave Portal
- Clave Gestiona
",
"NIF de cualquier empleado (que no esté en la lista negra y tenga acceso).",
"
SELECT e.NIF FROM EMPLEADOS e 
WHERE 
-- Usuario QA 
   e.reservado = 0
-- Elegimos uno al azar
ORDER BY RANDOM() LIMIT 1;
",
"Ejecuta escenarios de Menu.feature",
1
);

-----------------------------------------------------------------------

INSERT INTO FILE_METADATA (fm_pk, fm_literal, fm_title, fm_fichero, fm_datos, fm_query, fm_criterio, fm_obs, fm_activo)
VALUES (
20,
"PLAINMENU-02",
"Valida las opciones de menú de Gestiona.",
"CPA-WEB-PLAINMENU-02-Menu.txt",
"- NIF empleado cualquiera
- Clave Portal
- Clave Gestiona
",
"NIF de cualquier empleado (que no esté en la lista negra y tenga acceso).",
"
SELECT e.NIF FROM EMPLEADOS e 
WHERE 
-- Usuario QA 
   e.reservado = 0
-- Elegimos uno al azar
ORDER BY RANDOM() LIMIT 1;
",
"Ejecuta escenarios de Menu.feature",
1
);

-----------------------------------------------------------------------

INSERT INTO FILE_METADATA (fm_pk, fm_literal, fm_title, fm_fichero, fm_datos, fm_query, fm_criterio, fm_obs, fm_activo)
VALUES (
21,
"PLAINMENU-03",
"Valida las opciones de menú de Oficina virtual.",
"CPA-WEB-PLAINMENU-03-Menu.txt",
"- NIF empleado cualquiera
- Clave Portal
- Clave Gestiona
",
"NIF de cualquier empleado (que no esté en la lista negra y tenga acceso).",
"
SELECT e.NIF FROM EMPLEADOS e 
WHERE 
-- Usuario QA 
   e.reservado = 0
-- Elegimos uno al azar
ORDER BY RANDOM() LIMIT 1;
",
"Ejecuta escenarios de Menu.feature",
1
);

-----------------------------------------------------------------------

-- Commit de la transacción -----
COMMIT TRANSACTION;

-- Activamos las Foreing keys de nuevo para que se apliquen la restricciones de integridad
PRAGMA foreign_keys = on;
