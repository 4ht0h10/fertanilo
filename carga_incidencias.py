import sqlite3
import logging
import logging.config
import os
import yaml
import pandas as pd

##########################################################
#                                                        #
#      Script que carga los datos de incidencias         #
#      en la base de datos SQLite.                       #
#                                                        #
#      Los datos los extrae de un fichero Excel.         #
#                                                        #
##########################################################


# Establecer los ficheros de configuración y sus rutas
#   Parece un poco liada pero es para que sea agnóstico al
#   sistema de ficheros del SO.
#
ruta_params_config = os.path.join('conf', 'config.yaml')
ruta_fichero_log = os.path.join('logs', 'incidencias.log')

# Configuración del fichero de log
#
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(ruta_fichero_log),   # Saca a fichero
        logging.StreamHandler()                  # Saca a terminal
    ]
)
logger = logging.getLogger('incidencias')


# Carga parámetros del fichero de configuración
# usando la librería Yaml.
#
with open(ruta_params_config, 'r', encoding='utf-8') as file:
    config = yaml.safe_load(file)

# Definir el fichero y base de datos a usar:
#   - el fichero de input
#   - la base de datos destino
#
fichero_incidencias = config['ficheros']['incidencias']
BBDD = os.path.join(config['database']['path'], config['database']['name'])

# Lista ordenada del subconjunto de columnas que nos interesa:
#
columnas = [
    'CU',       # Código único de empleado
    'Tipo',     # Código del tipo de incidencia
    'Desde',    # Fecha de comienzo 
    'Hasta',    # Fecha de fin
]

def checking_input_file(file):
    ''' Audita le fichero de entrada para ver si tiene
        el formato correcto.
    '''

def inserta_incidencias():
    return '''
            INSERT INTO INCIDENCIAS (cu, causa, f_desde, f_hasta)
            VALUES (?,?,?,?)
           '''

def carga_incidencias():
    '''
    Parsea el .xlsx de entrada sacando todos los datos de incidencias
    e insertándolos en una base de datos SQLite.
 
    Primero recorre el fichero creando una lista de incidencias con sus datos.
    Luego procede a hacer un insert masivo en la tabla INCIDENCIAS de la BBDD.
    '''

    logger.info('Se inicia el proceso de carga de las incidencias ...')

    try:
        #######################################################
        #      Conecta a la Base de datos                     #
        #######################################################

        sqliteConnection = sqlite3.connect(BBDD)
        cursor = sqliteConnection.cursor()
        logger.debug("Establecida conexión con la base de datos %s", BBDD)

    except sqlite3.Error as error:
        logger.error("** ERROR conectando a %s: %s", BBDD, error)
        raise

    try:
        #######################################################
        #    Abrir el fichero Excel en la hoja adecuada.      #
        #######################################################

        df = pd.read_excel(
          # El fichero a leer en cuestión
          f"INPUT/{fichero_incidencias}",
          # La hoja concreta
          sheet_name='Incidencias',
          # Solo necesitamos determinadas columnas
          usecols=columnas
        )

    except Exception as error:
        logger.error("** ERROR abriendo el fichero %s : %s", fichero_incidencias, error)
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
                logger.warning("** ERROR: La columna %s no se encuentra en el DataFrame y esto va a petar", col)

        # Crea una lista de tuplas si todas las columnas existen
        #
        if all(col in df.columns for col in columnas):
            lista_de_tuplas = [tuple(x) for x in df[columnas].values]
            logger.info("Leídas %s filas (sin la cabecera)", str( len(lista_de_tuplas) ))
        else:
            logger.error("** ERROR: Algunas columnas no se encontraron en el DataFrame.")

        # Insert masivo en la BBDD SQLite de todas las tuplas
        #
        cursor.executemany( inserta_incidencias(),lista_de_tuplas)

        # Consolidar los cambios (commit)
        sqliteConnection.commit()
        logger.debug('Commit ejecutado')
        logger.info('Insertados correctamente los valores en la tabla INCIDENCIAS')

    except sqlite3.OperationalError as error:
        logger.error("** ERROR intentando alguna transacción con %s: %s", BBDD, error)
        raise

    except sqlite3.IntegrityError as error:
        logger.error("** ERROR de integridad referencial en %s: %s", BBDD, error)
        raise

    except sqlite3.Error as error:
        logger.error( "** ERROR con la BBDD SQLite %s: %s", BBDD, error)
        raise

    except OSError as error:
        logger.error( "** ERROR con una llamada al SO: %s", error )
        raise

    except EOFError as error:
        logger.error( "** ERROR de fin de fichero (EOF): %s", error )
        raise

    except KeyError as error:
        logger.error( "** Error KeyError: %s", error )
        raise

    except Exception as error:
        logger.error( '** ERROR procesando incidencias: %s', error)
        raise

    else:
        logger.info("Proceso de carga en BBDD de las incidencias desde %s ha terminado con éxito aparente", fichero_incidencias)

    finally:
        if ( sqliteConnection ):
            sqliteConnection.close()
            logger.debug("Cerrada la conexión SQLite")
        logger.info("Finalizado el proceso de carga de las incidencias")

if __name__ == '__main__':
    carga_incidencias()
