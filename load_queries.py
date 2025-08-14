import logging
import yaml
import sqlite3
import os

# Establecer las rutas y ficheros de configuración
#   Parece un poco liada pero es para que sea agnóstico al
#   sistema de ficheros.
#
ruta_params_config = os.path.join('conf', 'config.yaml')
ruta_fichero_log = os.path.join('logs', 'loadQueries.log')

# Configuración de los ficheros de log
#
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s-%(name)s-%(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(ruta_fichero_log),  # Saca a fichero
        logging.StreamHandler()                 # Saca a terminal
    ]
)
logger = logging.getLogger('queries')

# Carga parámetros del fichero de configuración
# usando la librería Yaml.
#
with open(ruta_params_config, 'r', encoding='utf-8') as file:
    config = yaml.safe_load(file)

# Establecer valores a usar para:
#   - nombre del script SQL a ejecutar
#   - nombre de la BBDD SQLite a crear
#
SCRIPT = os.path.join(config['database']['path'], config['database']['queries'])
BBDD   = os.path.join(config['database']['path'], config['database']['name'])

def create_queries_db():
    ''' Ejecuta el script de creación que carga en la
        BBDD los metadatos necesarios para generar los ficheros.
    '''

    try:
        #############################################
        #      Conecta a la Base de datos           #
        #############################################

        sqliteConnection = sqlite3.connect(BBDD)
        cursor = sqliteConnection.cursor()
        logger.debug("Establecida conexión con la base de datos %s", BBDD)

    except sqlite3.Error as error:
        logger.error(" ** ERROR conectando a %s: %s", BBDD, error)
        raise

    # Leer el fichero de script
    with open(SCRIPT, 'r', encoding='utf-8') as archivo:
        script_sql = archivo.read()
        logger.debug('Leído script %s que carga metadatos en BBDD', SCRIPT)

    try:
        # Ejecutar el script que carga los metadatos en BBDD
        #
        cursor.executescript(script_sql)

    except sqlite3.OperationalError as error:
        logger.error("** ERROR ejecutando el script BBDD %s: %s", SCRIPT, error)
        raise

    except sqlite3.IntegrityError as error:
        logger.error("** ERROR de integridad referencial al ejecutar %s: %s", BBDD, error)
        raise

    except sqlite3.Error as error:
        logger.error( "** ERROR trabajando con la BBDD SQLite; %s", error)
        raise

    except Exception as error:
        logger.error( '** ERROR procesando carga de metadatos: %s', error)
        raise

    else:
        logger.debug("Script SQL %s ejecutado con éxito", SCRIPT)

    finally:
        if ( sqliteConnection ):
            sqliteConnection.close()
            logger.debug("Cerrada la conexión SQLite")
        logger.info( "Finalizado %s que carga consultas y metadatos en la BBDD", __file__ )


if __name__ == '__main__':
    create_queries_db()
