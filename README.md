# Metronome Examples

A repository that shows the extendability of the
[Metronome](https://github.com/TM35-Metronome) project by writing commands for it in any
programming language.

## Example

The examples implement a super a simple command that randomizes starter Pokémons.
These examples are written to be simple first a formost, so some of them might assume certain
things about the data they get passes in:
* That there are at most 3 starters.
* That you can simply look at the biggest `pokemons` index to figure out the range of
  `0..N` to pick from.

In a real command, one should not assume these to be true:
* A game can have any number of starters
* Entries does not actually need to be continues. This is valid and should be handled:
```
.pokemons[1].hp=3
.pokemons[4].hp=1
.pokemons[7].hp=11
```

See [`tm35-rand-starters`](https://github.com/TM35-Metronome/metronome/blob/master/src/randomizers/tm35-rand-starters.zig)
for how this command would actually be written to handle everything correctly.

## Languages:
* [`c++`](cpp/main.cpp)
* [`c`](c/main.c)
* [`haskell`](haskell/Main.hs)
* [`x86_64 assembly (linux)`](x86_64/rand_starters.asm)
