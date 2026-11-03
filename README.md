# ClickThroughTrap

[Español](README.es.md)

A small World of Warcraft **3.3.5a** addon. While you are aiming a ground spell (Freezing Arrow, traps, Blizzard, Rain of Fire…), the focus, arena and target frames and your action bars turn see-through and the mouse clicks **through** them, so you can drop the spell right where those frames sit on the screen.

When the spell is placed or cancelled, everything goes back exactly as it was. Your keybinds keep working the whole time: only mouse clicks are let through.

## Features

- Focus, arena (Blizzard, Gladius, Gladdy, sArena, ElvUI, SUF, PitBull, X-Perl, Nidhaus) and, optionally, target frames.
- Optionally the action bars, including **nExtraBars**.
- Separate opacity for unit frames and for bars.
- Options and messages in English and Spanish (it follows the game language).
- Feed Pet is ignored: picking the food does not touch your bars.
- Safe in combat: protected frames get their mouse area back when combat starts, so the bars never get stuck unclickable.

## Usage

- `/ctt` opens the options (Interface → AddOns → ClickThroughTrap).
- `/ctt test` shows the effect for 8 seconds.
- `/ctt on` / `/ctt off`, `/ctt target on|off`, `/ctt bars on|off`
- `/ctt alpha 0.25`, `/ctt baralpha 0.35`
- `/ctt scan` names the frame under the mouse; `/ctt add <Frame>` adds it.

## Installation

1. Download the repository (**Code → Download ZIP**).
2. Copy the `ClickThroughTrap` folder into `World of Warcraft\Interface\AddOns`.
3. Restart the game or type `/reload`.
