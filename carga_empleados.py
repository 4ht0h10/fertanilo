import sqlite3
import logging
import logging.config
import os
import yaml
import pandas as pd

# Establecer las rutas y ficheros de configuración
#   Parece un poco liada pero es para que sea agnóstico al
#   sistema de ficheros.
#
ruta_params_config = os.path.join('conf', 'config.yaml')
ruta_fichero_log = os.path.join('logs', 'empleados.log')

# Configuración de los ficheros de log
#
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(ruta_fichero_log),  # Saca a fichero
        #TODO: quitar en ejecución desatendida
        logging.StreamHandler()                 # Saca a terminal
    ]
)
logger = logging.getLogger('empleados')

# Carga parámetros del fichero de configuración
# usando la librería Yaml.
#
with open(ruta_params_config, 'r', encoding='utf-8') as file:
    config = yaml.safe_load(file)

# Establecer parámetros a usar para:
#   - el fichero de input
#   - la base de datos destino
#
fichero_empleados = config['ficheros']['empleados']
BBDD = os.path.join(config['database']['path'], config['database']['name'])

# Lista ordenada de las columnas que nos interesan poniendo
# los nombres a nuestro gusto.
#
columnas = [
    'CU',                    # Código único de empleado
    'Nombre',                # Apellidos y nombre
    'NIF',                   # NIF
    'CodGrupo',              # Código del grupo al que pertenece el empleado
    'Plantilla',             # Código de la plantilla horaria
    'Días',                  # Número de días que trabaja a la semana
    'Alta',                  # Fecha de ingreso en la Organización
    'IRPF aplicado',         # Porcentaje de IRPF que se le aplica en nómina
    'IRPF calculado',        # Porcentaje de IRPF calculado por mes
    'IBAN',                  # Cuenta bancaria
    'Nombre chaleco',        # Nombre que figura en la tarjeta del chaleco
    'Solicitar IRPF'         # Dato calculado que indica si se puede cambiar IRPF
]

def checking_input_file(file):
    #TODO: usar esto?
    ''' Audita lel fichero de entrada para ver si tiene
        el formato correcto.
    '''

def inserta_empleado_generico():
    '''Devuelve un string con una query de un INSERT que puede emplearse
       para inserciones masivas de tuplas de valores en la base de datos
    '''
    return '''
            INSERT INTO EMPLEADOS (CU, nombre, NIF, grupo, plantilla, dias, f_incorporacion, irpf_aplicado, irpf_calculado, IBAN, tarj_chaleco, solicitar_irpf)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?)
           '''

def carga_empleados():
    '''
    Parsea el .xlsx de entrada sacando todos los datos de empleados
    e insertándolos en una base de datos SQLite.

    Primero recorre el fichero creando una lista de empleados con sus datos.
    Luego procede a hacer un insert masivo en la tabla EMPLEADOS de la BBDD.
    '''

    logger.info('Se inicia el proceso de carga de los empleados ...')

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
          f"INPUT/{fichero_empleados}",
          # La hoja concreta
          sheet_name='Empleados',
          # Solo necesitamos determinadas columnas
          usecols=columnas
        )

    except Exception as error:
        logger.error("** ERROR abriendo el fichero %s: %s", fichero_empleados, error)
        raise

    try:
        #######################################################
        #     Lee todos los empleados del fichero             #
        #     y los mete en una lista para posteriormente     #
        #     hacer un insert masivo de 'todos a una'.        #
        #######################################################

        # Verifica que las columnas existen en el DataFrame
        for col in columnas:
            if col not in df.columns:
                logger.error("** ERROR: La columna %s no se encuentra en el DataFrame y esto va a petar", col)

        # Crea una lista de tuplas si todas las columnas existen
        #
        if all(col in df.columns for col in columnas):
            lista_de_tuplas = [tuple(x) for x in df[columnas].values]
            logger.info("Leídas %s filas (sin la cabecera) del Excel de SAP", str( len(lista_de_tuplas) ))
        else:
            logger.error("** ERROR: Algunas columnas no se encontraron en el DataFrame.")

        # Insert masivo en la BBDD SQLite
        #
        cursor.executemany( inserta_empleado_generico(),lista_de_tuplas)

        # Consolidar los cambios (commit)
        #
        sqliteConnection.commit()
        logger.debug('commit ejecutado')
        logger.info('Insertados correctamente los valores en la tabla EMPLEADOS')

    except sqlite3.OperationalError as error:
        logger.error(" ** ERROR intentando alguna transacción con %s: %s", BBDD, error)
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

    except Exception as error:
        logger.error( '** ERROR insertando empleados: %s', error)
        raise

    else:
        logger.info("Proceso de volcado de empleados desde %s en la BBDD terminado con éxito aparente", fichero_empleados)

    finally:
        if (sqliteConnection):
            sqliteConnection.close()
            logger.debug("Cerrada la conexión con SQLite")
        logger.info("Ejecución de la carga de empleados terminada")

if __name__ == '__main__':
    carga_empleados()
