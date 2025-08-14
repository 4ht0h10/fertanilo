import logging
import yaml
import sqlite3
import os

# Establecer las rutas y ficheros de configuración
#   Parece un poco liada pero es para que sea agnóstico al
#   sistema de ficheros.
#
ruta_params_config = os.path.join('conf', 'config.yaml')
ruta_fichero_log = os.path.join('logs', 'createDB.log')

# Configuración de los ficheros de log
#
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(ruta_fichero_log),  # Saca a fichero
        logging.StreamHandler()                 # Saca a terminal
    ]
)
logger = logging.getLogger('createDB')

# Carga parámetros del fichero de configuración
# usando la librería Yaml.
#
with open(ruta_params_config, 'r', encoding='utf-8') as file:
    config = yaml.safe_load(file)

# Establecer valores a usar para 
#   - nombre del script SQL a ejecutar
#   - nombre de la BBDD SQLite a crear
#
SCRIPT = os.path.join(config['database']['path'], config['database']['create'])
BBDD   = os.path.join(config['database']['path'], config['database']['name'])

def create_database():
    ''' ejecuta el script de creación de la base de datos
        y carga inicial de tablas maestras.
    '''

    try:
        #######################################################
        #      Conecta a la Base de datos                     #
        #######################################################

        sqliteConnection = sqlite3.connect(BBDD)
        cursor = sqliteConnection.cursor()
        logger.debug("Establecida conexión con la base de datos %s", BBDD)

        # obtains DB version
        cursor.execute("select sqlite_version();")
        record = cursor.fetchall()
        logger.info("Versión de la base de datos SQLite: %s", record )

    except sqlite3.Error as error:
        logger.error(" ** ERROR conectando a %s: %s", BBDD, error)
        raise

    # Leer el fichero de script
    with open(SCRIPT, 'r', encoding='utf-8') as archivo:
        script_sql = archivo.read()
        logger.debug('Leído fichero script %s para la creación de BBDD', SCRIPT)

    try:
        # Ejecutar el script de creación
        #
        cursor.executescript(script_sql)

    except sqlite3.OperationalError as error:
        logger.error("** ERROR ejecutando el script BBDD %s: %s", BBDD, error)
        raise

    except sqlite3.IntegrityError as error:
        logger.error("** ERROR de integridad referencial al ejecutar %s: %s", BBDD, error)
        raise

    except sqlite3.Error as error:
        logger.error( "** ERROR trabajando con la BBDD SQLite; %s", error)
        raise

    except Exception as error:
        logger.error( '** ERROR creando la BBDD: %s', error)
        raise

    else:
        logger.info("Script %s de creación de la BBDD terminado con éxito", SCRIPT)

    finally:
        if (sqliteConnection):
            sqliteConnection.close()
            logger.debug("Cerrada la conexión con SQLite")
        logger.info( "Finalizada la ejecución de %s", __file__ )


if __name__ == '__main__':
    create_database()
