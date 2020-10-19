#!/usr/bin/env ruby
# encoding: utf-8
require 'rubygems'
require 'bundler/setup'

NombreDelPrograma = "passwordsCercanos"
Hoy = "2020-10-19"
Version = "0.1"
 
Copyright = 
"Programa: #{NombreDelPrograma}.rb\n" +
"Autor: Ángel García Baños\n" +
"Email: angarciaba@gmail.com\n" +
"Fecha creación: 2020-10-19\n" +
"Fecha última modificación: #{Hoy}\n" +
"Licencia: GNU-GPL"

Descripcion = 
"Cuando encriptas un archivo con zip pero comentes algún error con el password, este programa explora las alternativas más comunes, es decir, los passwords más cercanos al que creías, con errores de digitación de un espacio en blanco, una letra repetida, una letra faltante y un cambio de letra mayúscula/minúscula"
Dependencias =
"
rvm use 2.6.5
"
#-----------------------------------------------------------------------------------------------------------------------
# VERSIONES
# 0.1 The first one. 
#-----------------------------------------------------------------------------------------------------------------------
# Para ayudar a depurar:
def dd(expresion,env,mensaje="")
  puts "#{expresion}=#{env.eval(expresion)}  #{mensaje}\n==="
end
# Ejemplo:
# a="Hola"
# dd("a",binding)
#-----------------------------------------------------------------------------------------------------------------------
# Si el código es lento, puede hacerse un perfilado para buscar donde están las ineficiencias, poniento =true en la siguiente línea:
hacer_perfilado=false
if hacer_perfilado
  require 'ruby-prof'
  RubyProf.start
end
#-----------------------------------------------------------------------------------------------------------------------
# Muy útil para detectar cualquier tipo de objeto vacío o nulo:
class Object
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end
end
#-----------------------------------------------------------------------------------------------------------------------
require "open3" 
#-----------------------------------------------------------------------------------------------------------------------

archivo = "a.zip"
posiblePassword = "elperrodesanroquenotienecorona"

class PasswordsCercanos
  def initialize(verbose)
    @verbose = verbose
  end
  
  # Partir un string en dos trozos, de longitud progresivamente mayor:
  def trocear(texto)
    cantidadDeLetras = texto.size
    (0...cantidadDeLetras).each do |indice|
      trozo1 = texto[0...indice]
      trozo2 = texto[indice..cantidadDeLetras]
      yield trozo1, trozo2
    end
  end

  def buscar(archivo, posiblePassword)
    espacio = Proc.new { |texto| " " + texto }
    cambiarTipo = Proc.new { |texto| texto[0].swapcase + texto[1..-1] }
    repetir = Proc.new { |texto| texto[0] + texto }
    borrar = Proc.new { |texto| texto[1..-1] }

    [posiblePassword, posiblePassword.swapcase].each do |unPosiblePassword|
      [espacio, cambiarTipo, repetir, borrar]. each do |accion|
        trocear(unPosiblePassword) do |parteIzquierda, parteDerecha|
          password = parteIzquierda
          password << accion.call(parteDerecha)
          comando = 'unzip -o -P "' + password + '" ' + archivo
          p comando if @verbose
          exit_status = 0
          Open3.popen3(comando) do |stdin, stdout, stderr, wait_thread|
            pid = wait_thread.pid
            stdout.read
            exit_status = wait_thread.value
          end
          puts "EL PASSWORD ES:#{password}" if exit_status == 0
#          STDERR.puts "EL PASSWORD ES:#{password}" if exit_status == 0
        end
      end
    end
  end
end


#-----------------------------------------------------------------------------------------------------------------------
require 'optparse'

class ArgumentosEnLaLineaDeComandos < Hash
  def initialize(args)
    super()
    self[:archivo] = nil
    self[:password] = nil
        
    opciones = OptionParser.new do |opciones|
      opciones.banner = "Uso: #$0 [opciones]\n\n" + Descripcion + "\n\n" + Copyright + "\nVersión: " + Version + "\nDependencias:\n" + Dependencias + "\nOpciones:\n"

      opciones.on('-a=ARG', '--archivo=ARG', "El archivo .zip que se resiste a abrirse") do |archivo|
        self[:archivo] = archivo
      end

      opciones.on('-p=ARG', '--password=ARG', "El password con el que se encriptó el archivo, pero que debe tener alguna letra mal") do |archivo|
        self[:password] = archivo
      end

      opciones.on('-b', '--verbose', 'muestra los passwords explorados') do
        self[:verbose] = true
      end

      opciones.on('-v', '--version', 'muestra la versión') do
        puts Version
        exit
      end

      opciones.on_tail('-h', '--help', 'muestra esta ayuda y termina') do
        puts opciones
        exit
      end
    end

    opciones.parse!(args)
  end
  
  
  def booleano(argumento)
    not(argumento.downcase == 'false' or argumento.downcase == 'falso' or argumento.downcase == 'no' or argumento.downcase == 'nao')
  end

end

#-----------------------------------------------------------------------------------------------------------------------
require 'yaml'

if $0 == __FILE__
  argumentos = ArgumentosEnLaLineaDeComandos.new(ARGV)
  puts "Con -h puedes obtener ayuda, pues se requieren dos argumentos" if argumentos[:archivo].blank? and argumentos[:password].blank?
  passwordsCercanos = PasswordsCercanos.new(argumentos[:verbose])
  p argumentos[:archivo]
  p argumentos[:password]
  passwordsCercanos.buscar(argumentos[:archivo], argumentos[:password])
end

#-----------------------------------------------------------------------------------------------------------------------
if hacer_perfilado
  RubyProf::FlatPrinter.new(RubyProf.stop).print(STDOUT)
end
#-----------------------------------------------------------------------------------------------------------------------






