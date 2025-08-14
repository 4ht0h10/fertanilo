import sqlite3
import logging
import logging.config
import os
import yaml
import pandas as pd

##########################################################
#                                                        #
#      Script que carga los datos de anticipos de        #
#      nómina en la base de datos SQLite.                #
#                                                        #
#      Los datos los extrae de un fichero Excel.         #
#                                                        #
##########################################################


# Establecer los ficheros de configuración y sus rutas
#   Parece un poco liada pero es para que sea agnóstico al
#   sistema de ficheros.
#
ruta_params_config = os.path.join('conf', 'config.yaml')
ruta_fichero_log = os.path.join('logs', 'anticipos.log')

# Configuración del fichero de log
#
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s-%(name)s-%(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(ruta_fichero_log),   # Saca a fichero
        logging.StreamHandler()                  # Saca a terminal
    ]
)
logger = logging.getLogger('anticipos')


# Carga parámetros del fichero de configuración
# usando la librería Yaml.
#
with open(ruta_params_config, 'r', encoding='utf-8') as file:
    config = yaml.safe_load(file)

# Definir el fichero y base de datos a usar:
#   - el fichero de input
#   - la base de datos destino
#
fichero_anticipos = config['ficheros']['anticipos']
BBDD = os.path.join(config['database']['path'], config['database']['name'])

# Lista ordenada del subconjunto de columnas que nos interesa.
# Los nombres los hemos cambiado a nuestro gusto.
#
columnas = [
    'CU',                  # Código único de empleado
    'Fecha solicitud',     # Fecha de solicitud del anticipo
    'Tipo',                # Tipo de anticipo solicitado
    'Estado',              # Estado de tramitación del anticipo
    'Importe',             # Importe del anticipo solicitaado
    'Moneda'               # Número de días que trabaja a la semana
]

def inserta_anticipos():
    '''Devuelve un string con una query de un INSERT que puede emplearse
       para inserciones masivas de tuplas de valores en la base de datos
    '''
    return '''
            INSERT INTO ANTICIPOS (empleado, f_solicitud, tipo, estado, importe, moneda)
            VALUES (?,?,?,?,?,?)
           '''

def carga_anticipos():
    '''
    Parsea el .xlsx de entrada sacando todos los datos de anticipos
    e insertándolos en una base de datos SQLite.
 
    Primero recorre el fichero creando una lista de anticipos con sus datos.
    Luego procede a hacer un insert masivo en la tabla ANTICIPOS de la BBDD.
    '''

    logger.info('Se inicia el proceso de carga de los anticipos ...')

    try:
        #######################################################
        #      Conecta a la Base de datos                     #
        #######################################################

        sqliteConnection = sqlite3.connect(BBDD)
        cursor = sqliteConnection.cursor()
        logger.debug("Establecida conexión con base de datos %s", BBDD)

    except sqlite3.Error as error:
        logger.error("** ERROR conectando a %s: %s", BBDD, error)
        raise

    try:
        #######################################################
        #      Abrir el fichero Excel en la hoja adecuada.    #
        #######################################################

        df = pd.read_excel(
          # El fichero a leer en cuestión
          f"INPUT/{fichero_anticipos}",
          # La hoja concreta
          sheet_name='Anticipos',
          # Solo necesitamos determinadas columnas
          usecols=columnas
        )

    except Exception as error:
        logger.error("** ERROR abriendo el fichero %s : %s", fichero_anticipos, error)
        raise

    try:
        #######################################################
        #      Lee todos los anticipos del fichero            #
        #      y los mete en una lista para posteriormente    #
        #      hacer un insert masivo de todos a una.         #
        #######################################################

        # Verifica que las columnas existen en el DataFrame
        #
        for col in columnas:
            if col not in df.columns:
                logger.error("** ERROR: La columna %s no se encuentra en el DataFrame y esto va a petar", col)

        # Crea una lista de tuplas si todas las columnas existen
        #
        if all(col in df.columns for col in columnas):
            lista_de_tuplas = [tuple(x) for x in df[columnas].values]
            logger.info("Leídas %s filas (sin la cabecera)", str( len(lista_de_tuplas) ))
        else:
            logger.error("** ERROR: Algunas columnas no se encontraron en el DataFrame.")

        # Insert masivo en la BBDD SQLite
        #
        cursor.executemany( inserta_anticipos(),lista_de_tuplas)

        # Consolidar los cambios (commit)
        sqliteConnection.commit()
        logger.debug('Commit ejecutado')
        logger.info('Insertados correctamente los valores en la tabla ANTICIPOS')

    except sqlite3.OperationalError as error:
        logger.error(" ** ERROR intentando alguna transacción con %s: %s", BBDD, error)
        raise

    except sqlite3.IntegrityError as error:
        logger.error("** ERROR de integridad referencial en %s: %s", BBDD, error)
        raise

    except sqlite3.Error as error:
        logger.error( "** ERROR con la BBDD SQLite %s: %s", BBDD, error)
        raise

    except Exception as error:
        logger.error( '** ERROR insertando anticipos: %s', error)
        raise

    else:
        logger.info("Proceso de volcado de Anticipos en BBDD desde %s terminado con éxito aparente", fichero_anticipos)

    finally:
        if (sqliteConnection):
            sqliteConnection.close()
            logger.debug("Cerrada la conexión con SQLite")
        logger.info("Carga de anticipos terminada")

if __name__ == '__main__':
    carga_anticipos()
