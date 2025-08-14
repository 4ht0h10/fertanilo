import sqlite3
import os
import yaml
import logging
import logging.config


class FileGenerator():
    '''Clase magistral con métodos relacionados con la creación del fichero de datos.
       La clase crea un objeto que contiene todos los datos estáticos del fichero a
       crear salvo el resultado de la consulta a BBDD que se hará de forma dinámica
       con el método de la clase 'execute_query()'.
       También 
             '''

    def __init__(self, literal, title, file_name, datos, criteria, query, obs):
        self.literal = literal       # El identificador del caso de prueba
        self.title = title           # Título del caso de prueba
        self.file_name = file_name   # Nombre del fichero a crear
        self.datos = datos           # Nombre del fichero a crear
        self.criteria = criteria     # Criterio de busqueda en la BD
        self.query = query           # La select aplicada
        self.obs = obs               # Observaciones
        
        # Establecer las rutas y ficheros de configuración
        #   Parece un poco liada pero es para que sea agnóstico al
        #   sistema de ficheros.
        #
        paramsConfigFile = os.path.join('conf', 'config.yaml')
        rutaFicheroLog = os.path.join('logs', self.literal + '.log')
        
        # Carga parámetros del fichero de configuración
        # usando la librería Yaml.
        #
        with open(paramsConfigFile, 'r', encoding='utf-8') as file:
            config = yaml.safe_load(file)
        
        # Establecer parámetros a usar para:
        #   - la base de datos a consultar
        #   - el pass del usuario para el Portal
        #   - el pass del usuario para GESTIONA
        #
        self.BBDD = os.path.join(config['database']['path'], config['database']['name'])
        self.clavePortal = config['clavePortal']
        self.claveGestiona = config['claveGestiona']
        
        # Configuración del fichero de log
        #
        logging.basicConfig(
            level=logging.INFO,
            format="%(asctime)s-%(name)s-%(levelname)s- %(message)s",
            handlers=[
                logging.FileHandler(rutaFicheroLog),  # Saca a fichero
                #logging.StreamHandler()               # Saca a terminal
            ]
        )
        self.logger = logging.getLogger(self.literal)

    def execute_query(self, query):
        '''Ejecuta el código Select pasado por argumento y devuelve
           el resultado como una lista conteniendo una sola tupla.
        '''
        select = query
        resultado = "NO HAY DATOS"

        try:
            # Conecta a la Base de datos
            sqliteConnection = sqlite3.connect(self.BBDD)
            cursor = sqliteConnection.cursor()

            # Ejecuta la consulta para extrer los datos
            cursor.execute(select)

            # Obtiene el resultado
            datos = cursor.fetchall()

        except sqlite3.Error as error:
            self.logger.error("** ERROR sqlite3 operando con %s: %s", self.BBDD, error)
            raise

        finally:
            if ( sqliteConnection ):
                sqliteConnection.close()
                self.logger.debug("Finalizada conexión SQLite")
            self.logger.debug("Ejecución de la consulta %s terminada", self.literal)

        # Si la consulta devuelve datos los aplicamos al return
        if datos:
            self.logger.debug("La consulta no ha sido vacía")
            resultado = datos

        return resultado

    def compose_data_line(self, tupla):
        '''A partir de dos parámetros y una tupla de datos
        compone una línea con un formato predefinido.
        Transforma con sencillez y elegancia la tupla de entrada
        en un String con el formato adecuado'''

        # Descompone la lista de tuplas en el primer elemento (nif) más el resto (cola).
        # No me pidas que te lo explique, hace una hora lo hice y ya no me acuerdo.
        #
        nif = tupla[0][0]
        cola = "|".join(tupla[0][1:]) + "|" if tupla[0][1:] else " "

        # Compone el string final:
        # 'NIF' + 'Pass1' + 'Pass2' + 'el resto' si lo hay
        #
        return  f"{nif}|{self.clavePortal}|{self.claveGestiona}|{cola}"

    def write_file(self, line):
        '''Crea un fichero de texto con un nombre y contenido
         proporcionados por parametros.'''

        # Abre un fichero en modo escritura (write mode)
        with open('OUTPUT/' + self.file_name, 'w', encoding='utf-8') as fichero:
          # Escribe en el fichero la línea de datos a usar en los tests
            fichero.write(line + '\n\n')
          # A continuación escribe el resto de líneas:
            fichero.write(f"**** {self.literal}: {self.title} \n\n")
            fichero.write('**** DATOS:\n')
            fichero.write(self.datos + '\n')
            fichero.write('**** CRITERIO DE BUSQUEDA DE USUARIO:\n')
            fichero.write(self.criteria + '\n')
            fichero.write('\n**** QUERY:\n')
            fichero.write(self.query + '\n')
            if self.obs:
                fichero.write('**** OBSERVACIONES:\n')
                fichero.write(self.obs + '\n')

