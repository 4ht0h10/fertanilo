import json
from datetime import datetime

# Me dió por usar json... parecía una buena idea.
# ¡Ojo la elegante y retorcida manera de indexar atributos!:
#  Los diccionarios en Python no tienen un "orden" tradicional en versiones
#  anteriores a Python 3.7, pero a partir de Python 3.7 (y oficialmente en
#  Python 3.8+), mantienen el orden de inserción.

# Define los nombres de los archivos a usar
#
#archivo_entrada = 'ONCE-Portal.postman_test_run.json'
archivo_entrada = 'ONCE-Portal.postman_test_run_abril2025.json'
#archivo_salida  = 'usuarios sin acceso al portal.txt'
archivo_salida  = 'usuarios_sin_acceso_abril2025.txt'

# Define los contadores
#
COUNTER = 0
NOPASS_COUNTER = 0
VIRG_COUNTER = 0

# Obtener la hora actual en formato deseado
#
fecha_hora_actual = datetime.now().strftime("%d-%m-%Y %H:%M")

def obtener_lineas_allTests(json_data):
  """Obtiene un objeto Python proveniente de convertir un JSON
     y devuelve un objeto compuesto por diccionarios de dos items.

  Args:
      json_data (Object): objeto Python proveniente de convertir un JSON

  Returns:
      all_fallos: diccionarios de dos items
  """
  all_fallos = []
  # Iterar sobre el nodo 'results' y dentro de cada test en 'allTests'
  for result in json_data.get('results', []):
        for linea in result.get('allTests', []):
                all_fallos.append(linea)

  return all_fallos


if __name__ == '__main__':

 # Abre el archivo JSON de entrada en modo lectura y el de salida en modo escritura
 #
 with open(archivo_entrada, 'r', encoding='utf-8') as json_entrada, open(archivo_salida, 'w', encoding='utf-8') as txt_salida:

    txt_salida.write(" ------------------------------------------------------------------------\n")
    txt_salida.write("  RELACIÓN DE NIF SIN ACCESO AL PORTAL CON LAS CREDENCIALES DE TESTING\n")
    txt_salida.write(" ------------------------------------------------------------------------\n")

    # Convertimos el JSON en un objeto diccionario Python
    #
    data = json.load(json_entrada)

    # Obtener las líneas de allTests
    lineas = obtener_lineas_allTests(data)

    # Recorre la lista de objetos (cada objeto es un diccionario de dos elementos)
    #
    for objeto_linea in lineas:

        iterador = iter(objeto_linea.items())  # Crea un iterador de los pares clave-valor
        primera_clave, primer_valor = next(iterador)  # Obtiene el primer elemento
        segunda_clave, segundo_valor = next(iterador)  # Obtiene el segundo elemento

        if not (primer_valor and segundo_valor):
            if (primer_valor):
                print(segunda_clave + ' VIRGEN')
                txt_salida.write (segunda_clave + '\n')
                #txt_salida.write (segunda_clave + ' VIRGEN\n')
                COUNTER += 1
                VIRG_COUNTER += 1
            else:
                print(segunda_clave + ' NO ACCEDE')
                txt_salida.write (segunda_clave + '\n')
                #txt_salida.write (segunda_clave + ' NO ACCEDE\n')
                COUNTER += 1
                NOPASS_COUNTER += 1
        else:
            #txt_salida.write (segunda_clave + ' OK\n')
            print( segunda_clave + ' OK')


    txt_salida.write(" --------------------------------------------------------------------------\n")
    txt_salida.write(" [" + fecha_hora_actual + "] - Encontrados " + str(COUNTER) + " empleados que no acceden\n")
    txt_salida.write("   Usuarios con la clave incorrecta: " + str(NOPASS_COUNTER) + "\n")
    txt_salida.write("   Usuarios que nunca han entrado  : " + str(VIRG_COUNTER) + "\n")
    txt_salida.write(" --------------------------------------------------------------------------\n")

 print(f"Los {COUNTER} NIF sin acceso se han guardado en '{archivo_salida}'.")
