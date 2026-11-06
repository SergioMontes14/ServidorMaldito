# Servidor Maldito

Videojuego educativo de acción y terror cibernético (vista cenital, estilo Zelda) hecho en **Godot 4**.
Eres un ingeniero de software atrapado en un servidor infectado. Con una linterna de depuración debes
derrotar virus, recoger llaves criptográficas, viales de código y discos de respaldo, ensamblar el
**Antivirus Definitivo** y vencer al **Glitch Final**.

**Propósito pedagógico:** introducir al jugador en los conceptos básicos de los virus informáticos
(bug, bot, troyano, ransomware, spyware, rootkit, gusano, adware y keylogger) y en las buenas prácticas
de defensa (copias de seguridad, actualizaciones, antivirus). El juego incluye una **trivia de 7 preguntas
antes de jugar y la misma trivia al terminar los 4 niveles**, para medir cuánto aprendió el jugador.

## Cómo ejecutarlo
1. Instale Godot 4.3 o superior.
2. Abra Godot, pulse **Importar** y elija `project.godot`.
3. Pulse **F5**. (El juego arranca en la portada.)

## Controles
| Acción | Teclas |
|---|---|
| Moverse | W A S D o flechas |
| Disparar | J, Espacio o clic izquierdo |
| Usar vial | E o Q |
| Reiniciar nivel | R |
| Música (activar/silenciar) | M |

## Flujo del juego
1. **Portada** (JUGAR / CÓMO JUGAR / SALIR) → al pulsar JUGAR, **evaluación inicial** (7 preguntas). CÓMO JUGAR muestra controles, objetivo y objetos; SALIR cierra el juego.
2. Niveles 1 a 3: derrote al **virus élite** para obtener la **llave criptográfica** y abra el terminal.
   Cada nivel esconde un **disco de respaldo**; con los 3 se ensambla el Antivirus (disparos x2).
3. Nivel 4: jefe final **Glitch Final** (3 fases).
4. **Evaluación final** (las mismas 7 preguntas), resultados, comparación y repaso.

Los mapas incluyen bloques para cubrirse de los disparos. Los enemigos de cada nivel cambian **aleatoriamente** en cada partida. La primera vez que se encuentra
cada virus, el juego muestra una breve explicación (bestiario).

## Resultados de la evaluación
Al terminar la evaluación final se guarda una línea por partida en `resultados_trivia.csv`
(carpeta de datos de usuario de Godot; la ruta exacta aparece en la pantalla de resultados).
Columnas: fecha, puntaje inicial, puntaje final, mejora y acierto/fallo de cada pregunta (inicial y final).

## Estructura
```
assets/    sprites, items, tilesets, audio (efectos y música)
scenes/    escenas (niveles, jugador, enemigos, jefe, HUD, menú)
scripts/   código GDScript (level_data.gd define los niveles; trivia_data.gd las preguntas)
docs/      storyboard y hojas de sprites
web/       exportación Web para Vercel
```

## Publicar en Git y Vercel
```bash
git init
git add .
git commit -m "Servidor Maldito"
git branch -M main
git remote add origin <URL_DE_SU_REPOSITORIO>
git push -u origin main
```
1. En Godot: **Proyecto > Exportar > Añadir… > Web**. (El juego usa el renderizador *Compatibility*,
   obligatorio para la Web.) Desde Godot 4.3 la exportación sin hilos es la predeterminada.
   Exporte a `web/index.html` (se recomienda ese nombre).
2. Haga `git add web && git commit && git push`.
3. En Vercel: **Add New > Project**, importe el repositorio, **Framework Preset: Other**,
   **Output Directory: `web`**, sin comando de build. `vercel.json` ya lo configura.
4. Tras desplegar, abra la URL y pulse una tecla o haga clic para activar el audio (política de los navegadores).

## Créditos
- Código, diseño de niveles y audio sintetizado (Python/NumPy): proyecto del curso.
- Sprites: generados con IA generativa (Gemini) y procesados con Python/Pillow (recorte, fondo, recoloreo).
- Referencia de aprendizaje: tutorial de Brackeys "How to make a Video Game - Godot Beginner Tutorial".

## Bibliografía
- Souppaya, M., & Scarfone, K. (2013). *Guide to Malware Incident Prevention and Handling for Desktops and Laptops* (NIST SP 800-83 Rev. 1). https://doi.org/10.6028/NIST.SP.800-83r1
- CISA, FBI, NSA & MS-ISAC. *#StopRansomware Guide*. https://www.cisa.gov/stopransomware/ransomware-guide
- Godot Engine. *Exporting for the Web*. https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html
- Vercel. *Configuring Projects with vercel.json*. https://vercel.com/docs
