import logging
import logging.config
import os
import yaml
import pandas as pd

  ############################################################
  #                                                          #
  #    Script que extrae los datos de anticipos de nómina    #
  #    de empleado y los pone en un fichero Excel manejable. #
  #                                                          #
  #      Genera un fichero Excel ANTICIPOS.xlsx que será     #
  #      usado a su vez en otro proceso que carga esa        #
  #      información en una base de datos.                   #
  #                                                          #
  ############################################################

# Establecer las rutas y ficheros de configuración
#   Parece un poco liada pero es para que sea agnóstico al SO.
#
ruta_params_config = os.path.join('conf', 'config.yaml')
ruta_fichero_log = os.path.join('logs', 'pre_anticips.log')

# Configuración de los ficheros de log que llamaremos pre_ntcps
#
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s -%(levelname)s- %(message)s",
    handlers=[
        logging.FileHandler(ruta_fichero_log),  # Saca a fichero
        #TODO: quitar terminal para ejecución desatendida
        logging.StreamHandler()                 # Saca a terminal
    ]
)
logger = logging.getLogger('pre_anticip')

# Carga parámetros del fichero de configuración
# usando la librería Yaml.
#
with open(ruta_params_config, 'r', encoding='utf-8') as file:
    config = yaml.safe_load(file)

# Establecer los ficheros a usar sacados del config.
#   - fichero_input:  el fichero de input a procesar
#   - fichero_output: fichero resultante del pre-procesado
#   - dir_ficheros: directorio donde se encuentran los ficheros
#
fichero_input  = config['ficheros']['exportSAP1']
fichero_output = config['ficheros']['anticipos']
dir_ficheros   = config['inputDir']

logger.info('Se inicia el preprocesado de %s para sacar los anticipos de nómina...', fichero_input)

# Seleccionamos sólo las columnas que tiene datos de anticipos
# usando el índice de la columna para obtener las útiles.
# Las columnas que nos interesan para datos de anticipo son:
#   'Nº pers.', 'Número de personal', 'Fecha de solicitud',
#   'Subtipo', 'Estado', 'Importe', 'Moneda'
#
columnas_utiles = "A, B, M:Q"

# Elegimos unos nombres más apropiados que los originales
# para usar en el fichero de salida.
#
cabeceras = [
    'CU',                 # Código único de empleado
    'Nombre',             # Apellidos y nombre del empleado
    'Fecha solicitud',    # Fecha de solicitud del anticipo
    'Tipo',               # Tipo de anticipo
    'Estado',             # Estado de tramitación del anticipo
    'Importe',            # Importe del anticipo
    'Moneda',             # Moneda correspondiente al importe
]

def lee_excel_pandas():
    '''Lee los datos necesarios del fichero Excel'''

    data = pd.read_excel(
        f"{dir_ficheros}/{fichero_input}",
      # Elegimos la pestaña adecuada
        sheet_name='Format',
      # Sólo usamos los datos de anticipo
        usecols=columnas_utiles,
      # Le ponemos una relación de cabeceras a nuestro gusto
        names=cabeceras,
      # Convierte automáticamente la columna especificada en objetos tipo datetime
        parse_dates=['Fecha solicitud']
    )

    return data

def formatea_fechas(datf):
    '''Formatear la fechas al gusto'''

    datf['Fecha solicitud'] = pd.to_datetime(datf['Fecha solicitud'], errors='coerce')
    datf['Fecha solicitud'] = datf['Fecha solicitud'].dt.strftime('%Y-%m-%d')

    return datf

def elimina_filas_vacias(data):
    '''Elimina filas donde la columna "Fecha solicitud" tiene valores nulos'''

    data = data.dropna(subset=['Fecha solicitud'])

    return data

def volcar_fichero(dataframe):
    '''Vuelca el DataFrame en un nuevo fichero Excel'''

    dataframe.to_excel(
        f"{dir_ficheros}/{fichero_output}",
        sheet_name='Anticipos',
        index=False
    )
    logger.info('Creado correctamente el fichero %s', fichero_output)


if __name__ == '__main__':

    df = lee_excel_pandas()
    df = formatea_fechas(df)
    df = elimina_filas_vacias(df)
    volcar_fichero(df)
    logger.info('Finalizado el preprocesado de %s', fichero_input)
