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
ruta_fichero_log = os.path.join('logs', 'lista_negra.log')

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
logger = logging.getLogger('lista negra')

# Carga parámetros del fichero de configuración
# usando la librería Yaml.
#
with open(ruta_params_config, 'r', encoding='utf-8') as file:
    config = yaml.safe_load(file)

# Establecer parámetros a usar para:
#   - el fichero de input
#   - la base de datos destino
#   - el fichero donde se volcarán los errores de producirse
#
fichero_listanegra = config['ficheros']['reservados']
BBDD = os.path.join(config['database']['path'], config['database']['name'])
fichero_errores = 'OUTPUT/blacklist_update_errors.xlsx'

# Las columnas que usaremos de la hoja Excel
#
columnas = [
    'CU',       # Código único de empleado
    'DNI'       # NIF del empleado
]

# Lista para recopilar los posibles errores
# al intentar cada Update en la BBDD.
#
errores = []


####################################################
#      Conecta a la Base de datos                  #
####################################################
sqliteConnection = sqlite3.connect(BBDD)
cursor = sqliteConnection.cursor()
logger.debug("Establecida conexión con base de datos %s", BBDD)


def procesa_fila(fila):
    '''Función para procesar un registro actualizando con él la BBDD si procede.

       El registro es una tupla con dos valores:
       - CU: el identificador único de empleado
       - NIF: El NIF del empleado

      Devuelve una tupla <integer, string>.
      
      El entero es un código que indica el resultado del proceso y puede tener
      los siguientes valores:
      - 0: Empleado no existe en la actual base de datos
      - 1: El empleado ya aparecía como reservado previamente
      - 2: El empleado se ha actualizado como reservado
      - 3: Se ha producido un error en la operativa

      El string es un literal se reserva para recoger el mensaje de error cuando éste se produzca.
    '''

    update_query = """
         UPDATE EMPLEADOS
         SET reservado = 1
         WHERE CU = ? AND NIF = ?;
         """

    find_query = """
         SELECT e.CU, e.NIF, e.nombre, e.reservado  
         FROM EMPLEADOS e 
         WHERE e.CU = ? AND e.NIF = ?;
         """

    cu_value  = fila['CU']
    dni_value = fila['DNI']

    try:
        # Buscar al empleado por si no estuviese
        cursor.execute(find_query, (cu_value, dni_value))
        empleado = cursor.fetchone() # fetchone() devuelve una tupla con una fila o None si no encuentra nada

        # Si el empleado no existe en BBDD devuelve código '0'
        if  empleado is None:
            return 0, f" {cu_value} | {dni_value}  -  No aparece en la relación de empleados de la BBDD **"

        # Si el empleado ya estaba reservado de antes se devuelve código '1'
        if empleado[3] == 1:
            return 1, f"Empleado con código {cu_value} y NIF {dni_value} ya figuraba como reservado en BBDD"

        # Ejecutar Update
        cursor.execute(update_query, (cu_value, dni_value))
        sqliteConnection.commit()

        # Si esto no ha fallado es que lo ha actualizado: devolvemos código '2'
        return 2, f"Empleado con código {cu_value} y NIF {dni_value} ha sido actualizado como RESERVADO"

    except Exception as e:
        # Si ocurre un error, devolvemos código '3' y el mensaje del error
        logger.error("** ERROR: ha fallado el 'update' del empleado %s con NIF %s : %s",cu_value , dni_value, e)
        return 3, str(e)


def updates():
    """Actualiza en BBDD los empleados que lee del Excel de entrada como 'reservados'.
       Saca un fichero con el resultado de cada 'update' para tener una relación de los
       que se han actualizado y los que no se han podido actualizar.
       Igualmente genera un Excel con errores de la operación de BBDD si se producen.
    """

    try:
        #######################################################
        #      Abrir el fichero Excel en la hoja adecuada.    #
        #######################################################
        df = pd.read_excel(
          # El fichero a leer en cuestión
          f"INPUT/{fichero_listanegra}",
          # La hoja concreta
          sheet_name='ListaNegra',
          # Sin contar la cabecera
          header=0,
          # Necesitamos las dos columnas antes recogidas
          usecols=columnas
        )
        # Convertir la columna 'CU' a string
        df['CU'] = df['CU'].astype(str)
        logger.info("Vamos a procesar los %s empleados del fichero %s \n", len(df), fichero_listanegra)
    except Exception as error:
        logger.error("** ERROR abriendo el fichero %s: %s", fichero_listanegra, error)
        raise
    try:
      #####################################################
      #     Lee todos los empleados del fichero           #
      #     y los va procesando fila a fila para          #
      #     hacer su UPDATE si corresponde.               #
      #####################################################
        # Iterar sobre cada fila del DataFrame
        #
        for index, fila in df.iterrows():
            resultado = procesa_fila(fila)
            if resultado[0] != 3:
                logger.info(resultado[1])
            # Actuar en caso de error
            if resultado[0] == 3:
                errores.append({"Código de empleado": fila["CU"], "Mensaje de error": resultado[1]})
    except Exception as error:
        logger.error("** ERROR en función update(): %s", error)
        raise
    else:
        logger.info("Proceso de update de empleados reservados que figuraban en %s terminado con éxito", fichero_listanegra)
    finally:
        if (sqliteConnection):
            sqliteConnection.close()
            logger.debug("Cerrada la conexión con SQLite")
        logger.info("Carga de empleados reservados en BBDD terminada")
    # Si hay errores va a guardar los errores en un fichero Excel
    #
    if errores:
        # Crear un DataFrame con los errores y los vuelca en un fichero para su revisión
        df_errores = pd.DataFrame(errores)
        df_errores.to_excel(fichero_errores, index=False)
        logger.info("Se encontraron %s errores. \nVer %s para más detalle", len(errores), fichero_errores)
    else:
        logger.info("Script %s felizmente acabado sin errores", __file__)


if __name__ == '__main__':
    updates()
