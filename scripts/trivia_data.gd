extends RefCounted
# 7 preguntas sobre virus informaticos (evaluacion inicial y final).
# "answer" es el indice de la opcion correcta dentro de "options".

const QUESTIONS = [
	{
		"q": "En el juego, el «Bug» (araña de circuitos) representa un error de programación. ¿Qué es un bug de software?",
		"options": [
			"Un error en el código que causa fallos y puede ser explotado",
			"Un programa que limpia virus automáticamente",
			"Una copia de seguridad cifrada del sistema",
			"Un cable dañado dentro del servidor",
		],
		"answer": 0,
		"short": "Bug",
		"review": "Error de programación; si un atacante lo aprovecha, es una vulnerabilidad.",
	},
	{
		"q": "¿Qué tipo de malware se disfraza de programa legítimo para engañar al usuario?",
		"options": [
			"Troyano",
			"Gusano",
			"Cortafuegos (firewall)",
			"Copia de seguridad",
		],
		"answer": 0,
		"short": "Troyano",
		"review": "Parece un programa útil, pero oculta código malicioso.",
	},
	{
		"q": "¿Qué hace un ransomware?",
		"options": [
			"Cifra los archivos y exige un pago para devolverlos",
			"Muestra publicidad no deseada",
			"Acelera el computador",
			"Borra solo la caché del navegador",
		],
		"answer": 0,
		"short": "Ransomware",
		"review": "Secuestra los datos cifrándolos y pide un rescate.",
	},
	{
		"q": "¿Qué hace un spyware?",
		"options": [
			"Espía en secreto la actividad del usuario y envía los datos a terceros",
			"Repara archivos dañados",
			"Bloquea las ventanas emergentes",
			"Actualiza el sistema operativo",
		],
		"answer": 0,
		"short": "Spyware",
		"review": "Recopila información (contraseñas, hábitos) sin que lo sepas.",
	},
	{
		"q": "¿Qué caracteriza a un rootkit?",
		"options": [
			"Se oculta en el sistema con privilegios altos y es difícil de detectar",
			"Solo muestra anuncios en pantalla",
			"Es un antivirus gratuito",
			"Solo infecta hojas de cálculo",
		],
		"answer": 0,
		"short": "Rootkit",
		"review": "Se esconde con privilegios elevados para pasar desapercibido.",
	},
	{
		"q": "¿Cómo se propaga un gusano (worm)?",
		"options": [
			"Se copia a sí mismo por la red sin que el usuario haga nada",
			"Necesita que el usuario lo ejecute manualmente cada vez",
			"Solo infecta equipos apagados",
			"Únicamente se propaga con memorias USB físicas",
		],
		"answer": 0,
		"short": "Gusano",
		"review": "Se replica y viaja por la red por sí solo.",
	},
	{
		"q": "¿Cuál es la mejor defensa para no perder tus datos ante un ransomware?",
		"options": [
			"Tener copias de seguridad (backups) actualizadas",
			"Pagar el rescate de inmediato",
			"Desactivar el antivirus",
			"Usar la misma contraseña en todas las cuentas",
		],
		"answer": 0,
		"short": "Copias de seguridad",
		"review": "Un backup (el disco de respaldo del juego) permite recuperar los datos.",
	},
]
