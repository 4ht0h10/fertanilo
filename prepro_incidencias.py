import logging
import logging.config
import os
import yaml
import pandas as pd

  ##########################################################
  #                                                        #
  #    Script que extrae los datos de incidencias          #
  #    del empleado.                                       #
  #    Incidencia llaman a todo aquello que altera la      #
  #    jornada laboral del trabajador.                     #
  #                                                        #
  #    El fichero fuente mezcla incidencias tipo           #
  #   'absentismo' y tipo 'suplencia' que son los          #
  #    criterios que se usan en el depto. de RRHH.         #
  #    Para solucionar esto se usan dos DataFrames         #
	#    distintos que luego se combinan.                    #
  #                                                        #
  #    Genera un fichero Excel INCIDENCIAS.xlsx que        #
  #    será usado a su vez en otro proceso para cargar esa #
  #    información en una base de datos.                   #
  #                                                        #
  ##########################################################

# Establecer las rutas y ficheros de configuración
#   Parece un poco liada pero es para que sea agnóstico al SO.
#
ruta_params_config = os.path.join('conf', 'config.yaml')
ruta_fichero_log = os.path.join('logs', 'pre_incis.log')

# Configuración del fichero de log que llamaremos pre_incis
#
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s -%(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(ruta_fichero_log),  # Saca a fichero
        #TODO: quitar en ejecución desatendida
        logging.StreamHandler()                 # Saca a terminal
    ]
)
logger = logging.getLogger('pre_incis')

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
fichero_input  = config['ficheros']['exportSAP2']
fichero_output = config['ficheros']['incidencias']
dir_ficheros   = config['inputDir']

logger.info('Se inicia el preprocesado de %s para sacar ausencias del empleado...', fichero_input)


# Seleccionamos sólo las columnas que tiene datos propios de
# la incidencia usando el índice de la columna.
#
# DataFrame1 (absentismo)
# Las columnas que nos interesan para datos de absentismo son:
#   'Nº pers.', 'Número de personal', 'ClAb', 'Clase de absentismo', 'Desde', 'hasta'
#
# DataFrame2 (suplencias)
# Las columnas que nos interesan para datos de suplencias son:
#   'Nº pers.', 'Número de personal', 'Cl.', 'Clase de suplencia', 'Desde', 'hasta'
#
columnas_df1 = "A, B, E:H"
columnas_df2 = "A, B, I:L"

# Elegimos unos nombres chulos para las columnas definitivas
#
cabeceras = [
  'CU',               # Código único de empleado
  'Nombre',           # Apellidos y nombre del empleado
  'Tipo',             # Código de incidencia
  'Descripción',      # Descripción de la incidencia
  'Desde',            # Fecha de inicio
  'Hasta',            # Fecha de fin
]

def read_dataframe(columns: list):
    '''Lee los datos de absentismo o de suplencias del fichero Excel
       devolviendo un DataFrame.
       Recibe una lista de columnas según interese absentismo o suplencia.'''

    data = pd.read_excel(
      f"{dir_ficheros}/{fichero_input}",
      # Elegimos la pestaña adecuada
      sheet_name='Format',
      # Sólo usamos los datos incidencias
      usecols=columns,
      # Le ponemos nombres a nuestro gusto a las columnas
      names=cabeceras,
      # Convierte la columna especificada en objetos tipo 'datetime'
      parse_dates=[4,5] # Las columnas de fechas 'desde' y 'hasta'
    )

    return data

def formatea_fechas(datfx, col1: int, col2: int):
    '''Formatear la fechas como 'dd-mm-aaaa'
       Los parámetros son el DataFrame y las dos columnas a tratar'''

    datfx[col1] = pd.to_datetime(datfx[col1], errors='coerce')
    datfx[col1] = datfx[col1].dt.strftime('%Y-%m-%d')

    datfx[col2] = pd.to_datetime(datfx[col2], errors='coerce')
    datfx[col2] = datfx[col2].dt.strftime('%Y-%m-%d')

    return datfx

def elimina_vacios_df(data):
    '''Elimina filas donde las columnas "Desde"
    y "Hasta" tienen valores nulos'''

    data = data.dropna(subset=['Desde', 'Hasta'])

    return data

def concatena_df(dataf1, dataf2):
    '''Concatena los dos DataFrame pasados por parámetro'''

    # Anexa (concatena) los DataFrames
    df_concatenado = pd.concat([dataf1, dataf2], ignore_index=True)

    return df_concatenado

def ordenar_excel(dtf, col1, col2):
    """Ordena el dataframe por el valor de dos columnas.
    Recibe un DataFrame a ordenar y los dos atributos.
    Primero ordena por 'col1' en orden ascendente y por
    'col2' también en orden ascendente.
  
    Args:
        dtf (data frame): Data frame a ordenar
        col1 (String): columna por la que ordenar primero
        col2 (String): columna por la que ordenar después
  
    Returns:
        Data frame: Data frame ordenado
    """
    df_ordenado = dtf.sort_values(by=[col1, col2], ascending=[True, True])
  
    return df_ordenado

def eliminar_repetidos(datfrm):
    '''Elimina las filasrepetidas en el dataframe pasado por argumento'''
    df_sin_duplicados = datfrm.drop_duplicates()

    return df_sin_duplicados

def volcar_fichero(dataframe):
    '''Vuelca el DataFrame en un fichero Excel de incidencias'''
    dataframe.to_excel(
        f"{dir_ficheros}/{fichero_output}",
        sheet_name='Incidencias',
        index=False
    )
    logger.info('Creado correctamente el fichero %s', fichero_output)


if __name__ == '__main__':

    df1 = read_dataframe(columnas_df1)
    df2 = read_dataframe(columnas_df2)
    df1 = formatea_fechas(df1, 'Desde', 'Hasta')
    df2 = formatea_fechas(df2, 'Desde', 'Hasta')
    df  = concatena_df(df1, df2)
    df  = elimina_vacios_df(df)
    df  = ordenar_excel(df, 'CU', 'Desde')
    df  = eliminar_repetidos(df)
    volcar_fichero(df)
    logger.info('Finalizado el preprocesado de %s', fichero_input)
