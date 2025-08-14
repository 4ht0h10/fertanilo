import sqlite3
from typing import TextIO


archivo_entrada = 'usuarios_sin_acceso.txt'
archivo_salida = 'resultado_update_acesos.txt'
BBDD = "../db/db_v20250306.db"

update_query = """
     UPDATE EMPLEADOS
     SET reservado = ?
     WHERE NIF = ?;
     """

find_query = """
     SELECT e.CU, e.NIF, e.nombre, e.reservado  
     FROM EMPLEADOS e 
     WHERE e.NIF = ?;
     """

def actualiza_usuarios_sin_acceso(ficheroIN: TextIO, ficheroOUT: TextIO):
    """Marca en la BD los empleados sin acceso estándar al portal para no usarlos.
  
    Args:
      ficheroIN (fichero): Fichero con los NIF de los empleados a procesar
      ficheroOUT (fichero): Fichero donde se vuelca el detalle del proceso
    """
    # Abre el archivo de entrada en modo lectura y el de salida en modo escritura
    with open(ficheroIN, 'r', encoding='utf-8') as entrada, open(ficheroOUT, 'w', encoding='utf-8') as salida:
        salida.write(" --------------------------------------------------------------------------\n")
        salida.write("   ACTUALIZACIÓN CON LOS EMPLEADOS QUE NO HACEN LOGIN\n")
        salida.write(" --------------------------------------------------------------------------\n\n")
        salida.write(" Posibles estados del empleado:\n")
        salida.write("  0 - El empleado se puede usar en los test por parte del equipo QA\n")
        salida.write("  1 - Reservado en la lista negra, no se deben usar por parte del equipo QA\n")
        salida.write("  2 - Se podría usar por QA pero no accede al portal con el password que se supone le corresponde\n")
        salida.write("  3 - Estaba ya reservado en la lista negra, pero es que además no accede con el pass\n")
        salida.write("  4 - Empleado teoricamente disponible pero no ha accedido nunca y le obliga a cambiar la clave\n")
        salida.write("  5 - Empleado que no se puede usar y además no ha accedido nunca y le obliga a cambiar la clave\n")
        salida.write("  6 - Empleado 'quemado'. Usado en algún test previo que ha cambiado su situación administrativa\n")
        salida.write(" --------------------------------------------------------------------------\n\n")
    
        # Recorre cada línea del archivo de entrada
        for linea in entrada:
            # Procede con el NIF de turno
            result = update_usuario(linea.strip())
            salida.write(result[1] + "\n")

def update_usuario(nif):
    """ Actualiza en la BD el usuario correspondiente como 'no accede al Portal'
        La actuaización que haga dependerá de la situación de dicho empleado
        en el momento.

    Args:
      nif (string): El NIF del empleado sobre el que va a hacer el update.

    Returns:
      int:    Código asociado al resultado
      String: Mensaje con el resultado 
    """

    try:
        # Conecta a la Base de datos 
        sqliteConnection = sqlite3.connect(BBDD)
        cursor = sqliteConnection.cursor()
    except sqlite3.Error as error:
        print(f"** [Error] al intentar conectarse a {BBDD} : {error}")
        raise

    try:
        # Buscar al empleado para proceder
        #
        cursor.execute( find_query, (nif,) )

        # fetchone() devuelve una tupla con una fila o 'None' si no encuentra
        #
        empleado = cursor.fetchone()

        # Si el empleado no existe en BBDD malamente hace nada con él
        if  empleado is None:
           return 9, f"\n** [WARNING] {nif} - No aparece en la BBDD **\n"

        # Si el empleado estaba disponible pasa a estado '2'
        if empleado[3] == 0:
          cursor.execute( update_query,( 2, nif)  )
          sqliteConnection.commit()
          return 0, f"--> CAMBIO: {nif} - El empleado estaba disponible y pasa a estado {empleado[3]} <--"

        # Si el empleado estaba reservado pasa a estado '3'
        if empleado[3] == 1:
          cursor.execute( update_query, (3, nif)  )
          sqliteConnection.commit()
          return 1, f"--> CAMBIO: {nif} - El el empleado estaba reservado y pasa a estado {empleado[3]} <--"

        # Si el empleado estaba disponible y sin acceso se queda así
        if empleado[3] == 2:
          return 2, f"QUEDA COMO ESTABA - {nif} - Empleado estaba disponible y sin acceso se queda en estado {empleado[3]}"

        # Si el empleado estaba reservado y sin acceso se queda así
        if empleado[3] == 3:
          return 3, f"QUEDA COMO ESTABA - {nif} - Empleado estaba reservado y sin acceso se queda en estado {empleado[3]}"

        # Ninguno de los casos anteriores
        return 5, f"QUEDA COMO ESTABA - {nif} - Estado {empleado[3]}"

    except Exception as e:
        print(f"\n** [ERROR]: ha fallado el 'update' del empleado con NIF {nif} **\n")
        raise(e)


if __name__ == '__main__':
    print(f"\nProcede a ejecutar la actualización de BBDD con los usuarios de {archivo_entrada}\n", )
    actualiza_usuarios_sin_acceso(archivo_entrada, archivo_salida)
    print(f"\nEjecutado script con éxito\nEl detalle está en el archivo: {archivo_salida}\n", )
