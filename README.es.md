# ClickThroughTrap

[English](README.md)

Un addon chico para World of Warcraft **3.3.5a**. Mientras apuntás un hechizo de suelo (Flecha congelante, trampas, Ventisca, Lluvia de fuego…), los marcos de focus, arena y objetivo y tus barras de acción se vuelven transparentes y el mouse los **atraviesa**, así podés tirar el hechizo justo donde están esos marcos en la pantalla.

Cuando lo tirás o lo cancelás, todo vuelve exactamente a como estaba. Las teclas siguen funcionando todo el tiempo: solo se deja pasar el click del mouse.

## Qué hace

- Marcos de focus, arena (Blizzard, Gladius, Gladdy, sArena, ElvUI, SUF, PitBull, X-Perl, Nidhaus) y, si querés, el de objetivo.
- Si querés, las barras de acción, incluidas las de **nExtraBars**.
- Opacidad aparte para los marcos y para las barras.
- Opciones y mensajes en inglés y en español (según el idioma del juego).
- Alimentar mascota se ignora: elegir la comida no toca tus barras.
- Seguro en combate: los marcos protegidos recuperan el click al entrar en combate, así las barras nunca quedan trabadas.

## Uso

- `/ctt` abre las opciones (Interfaz → Accesorios → ClickThroughTrap).
- `/ctt test` muestra el efecto durante 8 segundos.
- `/ctt on` / `/ctt off`, `/ctt target on|off`, `/ctt bars on|off`
- `/ctt alpha 0.25`, `/ctt baralpha 0.35`
- `/ctt scan` dice qué marco hay bajo el mouse; `/ctt add <Marco>` lo agrega.

## Instalación

1. Descargá el repositorio (**Code → Download ZIP**).
2. Copiá la carpeta `ClickThroughTrap` en `World of Warcraft\Interface\AddOns`.
3. Reiniciá el juego o escribí `/reload`.
