import logging
import logging.config
import os
import yaml
import pandas as pd

 ##########################################################
 #                                                        #
 #      Script que extrae los datos de empleados de       #
 #      la organización.                                  #
 #                                                        #
 #      Genera el fichero Excel "EMPLEADOS.xlsx" que será #
 #      usado a su vez en otro proceso para cargar esa    #
 #      información en una base de datos.                 #
 #                                                        #
 ##########################################################

# Establecer las rutas y ficheros de configuración
#   Parece un poco liada pero es para que sea agnóstico al SO.
#
ruta_params_config = os.path.join('conf', 'config.yaml')
ruta_fichero_log   = os.path.join('logs', 'pre_empleados.log')

# Configuración de los ficheros de log
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
logger = logging.getLogger('pre_empl')

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
fichero_output = config['ficheros']['empleados']
dir_ficheros   = config['inputDir']

logger.info('Se inicia el preprocesado de %s para sacar los datos de los empleados...', fichero_input)


# Seleccionamos sólo las columnas que tiene datos de empleado
# usando el índice de la columna para obtener su rango.
# Las columnas que nos interesan para empleados son:
#   'Nº pers.', 'Número de personal', 'NIF', 'GrPer', 'Grupo de personal',
#   'Regla para plan horario trabaj', 'DíaLS', 'Fecha', 'Porcentaje aplicado',
#   'Porcentaje Nómina', 'IBAN', 'Nom.Tarj.Chal.'
#
rango = range(0,12)

# Elegimos unos nombres más apropiados que los originales
#
cabeceras = [
    'CU',                # Código único de empleado
    'Nombre',            # Apellidos y nombre
    'NIF',               # NIF
    'CodGrupo',          # Código del grupo en el que aparece el empleado
    'Grupo',             # Nombre del grupo al que pertenece el empledo
    'Plantilla',         # Código de la plantilla horaria
    'Días',              # Número de días que trabaja a la semana
    'Alta',              # Fecha de ingreso en la Organización
    'IRPF aplicado',     # Porcentaje de IRPF que se le aplica en nómina
    'IRPF calculado',    # Porcentaje de IRPF calculado por mes
    'IBAN',              # Cuenta bancaria en formato IBAN
    'Nombre chaleco',    # Nombre que figura en la tarjeta del chaleco
]


def corrige_nif(stringNIF):
    '''Acorta un string que pretende ser un NIF
    limitándolo a los 9 primeros caracteres.
    Originalmente de SAP nos lo dan con unos cuantos
    espacios en blanco y acabado en un '1' que nadie
    nos sabe decir que pinta'''

    return stringNIF[:9]

def read_data_pandas():
    '''Lee el fichero Excel origen usando para ello la librería Pandas.'''

    data = pd.read_excel(
            f"{dir_ficheros}/{fichero_input}",
          # Selecciona la hoja buena, las demás sobran
            sheet_name='Format',
          # Sólo los datos de empleado
            usecols=list(rango),
          # Le ponemos al data frame una relación de cabeceras a nuestro gusto
            names=cabeceras,
          # Convierte automáticamente la columna especificada en objetos tipo 'datetime'
            parse_dates=['Alta']
    )

    return data

def formatea_fechas(datf):
  """Formatear la fecha de alta del empleado como %Y-%m-%d

  Args:
      datf (_DataFrane): un objeto dataframe de Pandas

  Returns:
      DataFrame: Un dataframe con el atiuto 'Alta' en el formato deseado
  """

  datf['Alta'] = pd.to_datetime(datf['Alta'], errors='coerce')
  datf['Alta'] = datf['Alta'].dt.strftime('%Y-%m-%d')

  return datf

def the_last_of_us(data):
    '''Agrupa por el código de empleado y
    selecciona la última fila de cada grupo'''

    df_last = data.groupby('CU').tail(1)

    return df_last

def porcentaje_irpf(irpf_aplicado, irpf_calculado):
    '''Devuelve si se puede pedir modificación del IRPF.
    Si no puede devuelve '0'.
    Y en caso afirmativo la cantidad de referencia para la 
    nueva retención, que debrá de ser mayor.'''

    if (irpf_aplicado == 0) & (irpf_calculado != 0):
        return irpf_calculado

    return 0

def crea_columna_irpf(dframe):

    dframe['Solicitar IRPF'] = dframe.apply(lambda row: porcentaje_irpf(row['IRPF aplicado'], row['IRPF calculado']), axis=1)

    return dframe

def volcar_fichero(dataframe):
    '''Vuelca el data frame en un nuevo fichero Excel'''

    dataframe.to_excel(
        f"{dir_ficheros}/{fichero_output}",
        sheet_name='Empleados',
        index=False
    )
    logger.info('Creado correctamente el fichero Excel %s', fichero_output)


if __name__ == '__main__':

    df = read_data_pandas()
    df['NIF'] = df['NIF'].apply(corrige_nif)
    df = formatea_fechas(df)
    df = the_last_of_us(df)
    df = crea_columna_irpf(df)
    volcar_fichero(df)
    logger.info('Finalizado preprocesado de %s para obtener los empleados', fichero_input)
