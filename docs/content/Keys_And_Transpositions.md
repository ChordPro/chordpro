---
title: Key/Value pairs
description: Key/Value pairs
---

# Keys and Transpositions

## Keys
The song key, as set with a `{key:}` directive is now checked for being a valid key.

See this [Wikipedia article](https://en.wikipedia.org/wiki/Key_(music)) for an extensive description of musical keys and signatures.

ChordPro considers keys as valid if there are at most five
sharp or flat accidentals: `C`, `D♭`, `D`, `E♭`, `E`, `F`, `F♯/G♭`, `G`, `A`, `B♭`,
`B`, and their minor equivalents, `Am`, `B♭m`, `Bm`, and so on. The
key `F♯/G♭` is an exception, since both the sharp form `F♯` and the flat
form `G♭` contain six accidentals. ChordPro will use `F#`, but see
[customizations]({{< relref "Keys_And_Transpositions#customizations" >}}).

Sharp keys are acceptable but will be treated as the corresponding flat key, e.g. `C♯` will become `D♭`. 

### Breaking changes (ChordPro 6.100)

Substitution variable `key` will always return the (possibly modified) key as set with the `{key:}` directive, regardless of capo and transpositions.

The key will be modified to its common enharmonic variant if there are more than five accidentals, i.e., `D♯` becomdes `E♭`. This behaviour can be disabled, see [customizations]({{< relref "Keys_And_Transpositions#customizations" >}}).

## Transpositions

There are several ways to transpose a song, either whole or partly.

* one or more `{transpose}` directives
* config setting `settings.transpose`, possibly overridden by command line option `--transpose` or GUI selection

A transposition has the form of a number, possibly negative, optionally postfixed by one of the letters `s`, `f`, and `k`. The number designates the number of intervals to transpose, and, by absense of a postfix, the transpose direction.

When a postfix is specified it determines whether the transpose should always produce sharp chords (postfix `s`), flat chords (postfix `f`), or follow the song key (postfix `k`). Without a postfix a negative number will produce flats, otherwise sharp chords are produced.

Note that transposing with `k` only makes sense if the song has a `{key:}` directive.

Two new substitution variables have been added:  
`key.print` will produce the (possibly transposed) key of the song.  
`key.sound` will produce the key as it sounds. This usually the same as `key.print` unless a `{capo:}` directive is used.

For example,
````
{capo: 2}
{transpose: 1}
{key: C}
# key = C, key.print = D♭, key.sound = E♭
````
Note that `settings.decapo` and command line option `--decapo` effectively turn `{capo: 2}` into `{transpose: 2}`. `key.print` will now be equal to `key.sound`:
````
# key = C, key.print = E♭, key.sound = E♭
````

### Breaking changes (ChordPro 6.100)

Substitution variables `key_actual` and `key_from` have been removed as being misleading and not useful.

When one of the postfix letters is used, the transpose interval is passed to delegates unchanged. E.g. `-1` no longer becomes `+11`. Yes, this means that you can now correctly transpose ABC sections without having to tweak octaves.

When using implied transpose direction, i.e. without a postfix, the behaviour is not changed when a new transpose uses an opposite sign. For example,

````
{transpose: -3}
# Uses flats
{transpose: 1}
# Still uses flats
````

## Customizations

New config variables:

### `keys.flats` (default: false)

Use the sharp enharmonic `F♯` for the key `F♯/G♭`.

### `keys.force-common` (default: true)

Enforce the common 'max 5 accidentals' variant of the keys.

If this is disabled, keys will be used as given but it may yield unexpected results when transposing.
