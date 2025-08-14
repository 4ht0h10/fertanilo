import logging
import os
import subprocess

##########################################################
#                                                        #
#      Script que centraliza todos los procesos          #
#      involucrados en la creación y carga de datos      #
#      en la base de datos SQLite, así como la           #
#      generación de ficheros de datos para los tests    #
#      automáticos.                                      #
#                                                        #
#      Los datos provienen originalmente de SAP          #
#      extraídos en forma de ficheros Excel.             #
#                                                        #
##########################################################

# Establecer la ruta y nombre del fichero de log
# Parece un poco liada pero es para que resulte agnóstico al
# sistema de ficheros.
#
ruta_fichero_log   = os.path.join('logs', 'orquestador.log')

# Configuración de los ficheros de log
#
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s-%(name)s-%(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(ruta_fichero_log),  # Saca a fichero
        logging.StreamHandler()                 # Saca a terminal TODO: Quitar para ejecución desasistida
    ]
)
logger = logging.getLogger('loader')

# Lista ordenada de scripts de la creación y carga
# de la BBDD.
#
scripts_loader = [
    "crea_basedatos.py",
    "prepro_empleados.py",
    "prepro_anticipos.py",
    "prepro_incidencias.py",
    "carga_empleados.py",
    "carga_anticipos.py",
    "carga_incidencias.py"
]

# Script que carga en la BBDD
# de las queries para el tratamiento de datos
# que creará los ficheros usados en los tests.
#
scripts_queries = [
    "load_queries.py"
]

# Lista ordenada de scripts de la generación
# de los ficheros de datos para los tests.
# Sí, ahora sólo hay uno.
#
scripts_generator = [
    "fertanilo_downloader.py"
]

def fertanilo_load_data_db():
    ''' Ejecuta una sucesión de procesos contenidos en la lista "scripts"
        usando la librería "subprocess"
        Obtiene la salida de error estándar de cada script y la incorpora
        a su propio log.
    '''

    # Ejecuta los scripts relativos a la creación y carga de datos en la BBDD
    #
    for script in scripts_loader:
        result = subprocess.run(["python", script], check = True, capture_output=True, text=True)
        logger.info( "Ejecutado script de carga %s con salida:\n%s", script , result.stderr)

def fertanilo_load_metadata_db():
    ''' Ejecuta una sucesión de procesos contenidos en la lista "scripts_queries"
        usando la librería "subprocess"
        Obtiene la salida de error estándar de cada script y la incorpora
        a su propio log.
    '''

    # Ejecuta los scripts relativos a meter metadatos de ficheros en BBDD
    #
    for script in scripts_queries:
        result = subprocess.run(["python", script], check = True, capture_output=True, text=True)
        logger.info( "Ejecutado script de carga de queries %s con salida:\n%s", script , result.stderr)


def fertanilo_file_creation_process():
    ''' Ejecuta una sucesión de procesos contenidos en la lista "scripts"
        usando la librería "subprocess"
        Obtiene la salida de error estándar de cada script y la incorpora
        a su propio log.
    '''

    # Ejecuta los scripts relativos al volcado de ficheros
    #
    for script in scripts_generator:
        result = subprocess.run(["python", script], check = True, capture_output=True, text=True)
        logger.info( "Ejecutado script de crear ficheros %s con salida:\n%s", script , result.stderr)

if __name__ == '__main__':
    fertanilo_load_data_db()
    fertanilo_load_metadata_db()
    fertanilo_file_creation_process()
