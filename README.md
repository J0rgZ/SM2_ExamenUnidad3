EXAMEN PRÁCTICO – UNIDAD III
Curso: Desarrollo de Aplicaciones Móviles
Tema: Automatización de calidad con GitHub Actions
Entrega: Readme.md convertido en PDF con evidencia y documentación
https://github.com/J0rgZ/SM2_ExamenUnidad3.git

link
Objetivo
Implementar un flujo de trabajo (workflow) automatizado en GitHub Actions para realizar análisis de calidad sobre tu proyecto móvil, integrando prácticas de DevOps.
Actividades a realizar
1.	Crear repositorio en GitHub
Crea un repositorio público en GitHub con el nombre exacto:
SM2_ExamenUnidad3
2.	Copiar tu proyecto móvil al nuevo repositorio
Copia todo el contenido de tu proyecto móvil desarrollado durante el curso (archivos y carpetas) al repositorio SM2_ExamenUnidad3.
Puedes hacerlo manualmente o clonando el repositorio y luego moviendo el código allí.

3.	Crear el workflow de GitHub Actions
Dentro de tu proyecto (la raíz), crea las siguientes carpetas en la raíz del repositorio:
.github/workflows/
test/

Dentro de workflows, crea un archivo llamado: quality-check.yml
Dentro de test, crea un archivo llamado: main_test.dart  

4.	Agregar un workflow básico
El archivo main_test.dart, debe contener al menos 3 prueba unitarias.
En el archivo quality-check.yml, escribe un flujo de trabajo que se ejecute automáticamente cuando se haga un commit o un pull request.
Puedes utilizar este ejemplo como plantilla si tu proyecto es Flutter:

------------------------------------------------------------------------------
name: Quality Check

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  analyze:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'  # ajusta a tu versión de Flutter

      - name: Install dependencies
        run: flutter pub get

      - name: Analyze
        run: flutter analyze

      - name: Run tests
        run: flutter test
------------------------------------------------------------------------------
flutter analyze - Verifica que el código cumpla con las buenas prácticas de estilo, convenciones y que no haya errores sintácticos. Ideal para detectar warnings, imports innecesarios, nombres mal definidos, etc.
flutter test - Ejecuta las pruebas automatizadas que hayas definido en la carpeta test/. Esto asegura que las funciones críticas de tu app siguen funcionando correctamente tras cada cambio.
Nota. Si tu proyecto es de otra tecnología (React Native, Kotlin, etc.), adapta el contenido del workflow según corresponda.

5.	Verificar ejecución automática
Una vez subido el archivo al repositorio, realiza un commit o pull request.
Luego, verifica que el workflow se haya ejecutado automáticamente desde la pestaña Actions en GitHub.
Al hacer git push al repositorio en la rama main o al crear un pull request hacia main. GitHub ejecutará automáticamente: flutter analyze sobre todo el proyecto y  flutter test sobre todo el contenido de la carpeta test/
6.	Resultados para el informe
el resultado de quality-check.yml debe ser 100% passed, resultados incompletos automáticamente será 0
Entrega del informe (Readme.md convertido a PDF)
El informe debe estar realizado en el propio README.md del proyecto y debe contener lo siguiente:
•	Nombre del curso, Fecha, Nombres completos del estudiante.
•	URL del repositorio SM2_ExamenUnidad3 en GitHub.
•	Capturas de pantalla que evidencien:
o	Estructura de carpetas .github/workflows/.
o	Contenido del archivo quality-check.yml.
o	Ejecución del workflow en la pestaña Actions.
•	Explicación de lo realizado:
Consideraciones
•	Solo serán evaluados los exámenes que cumplan con los puntos anteriores.
•	El repositorio debe ser público.
•	El archivo quality-check.yml debe estar correctamente ubicado en .github/workflows/.
•	El workflow debe ejecutarse de forma automática.
•	El informe debe estar en formato PDF y tener una redacción clara.
En github donde visualizar la ejecución
•	Ve a tu repositorio en GitHub.
•	Haz clic en la pestaña “Actions”. Ahí verás una lista de ejecuciones recientes de tu workflow.
•	Puedes hacer clic sobre una ejecución para ver los pasos, salidas, errores, advertencias, etc.
