AutoChecklist
=============

A script I wrote because I don't want to sign up to MyAnimeList, so I
wrote my own ripoff of the most prominent feature: keeping a list of
your anime.

This tool lets you keep checklists (in a very specific format; covered
later), and will update items on the checklists by bringing them in from
the filesystem when you run this script.

Usage
-----

The general usage of this program follows this pattern:
```
auto-checklist filename.txt
```
Nothing more to it.

There are some command-line options described in
`auto-checklist --help`, but those are not necessary for normal
operation of this program and exist as shortcuts for operations you
could do yourself with a text editor.

File format
-----------

The file is divided up into sections.

### `From:`

Everything under the `From:` section must be a glob beginning with `- `
(a hyphen then a space). The glob will match directory names, and those
directories will then be automatically added as sections if they don't
exist. This allows you to manage new directories in a nice-ish way.

This gets placed at the beginning of the file when this script processes
it. All `From:` sections will be merged into one section.

### `Ignore:`

Everything under the `Ignore:` section is structured similarly to
everything under the `From:` section, except that instead of globs,
every filename is exactly specified.

These specify full paths (actually, directory path + forward slash +
filename), which will not be included when scanning directories.

This section gets placed at the end of the file once the script
processes it. As with `From:` sections, these will all be merged into
one.

### Directory sections

These can be automatically generated from directories matched by a glob
in a `From:` section, or you can add them manually. They will never be
deleted.

The section heading takes one of two forms:

* `= /path/to/dir:`
* `name = /path/to/dir:`

The name can be arbitrary, but take care not to use the equals sign in
the interests of not confusing the parser. Spaces around the equals sign
before the path are mandatory.

Entries in this section are different from entries in a `From:` or
`Ignore:` section. They take this form:

* `[x] Filename`

Where `x` is any sequence of characters other than `]` or the newline
character (but is usually just one character), and where `Filename` is
an exact filename usually corresponding to a directory entry found under
this section's path.

The `x` (in whatever form it may be) is referred to as the check-mark,
and the entire line is an item. Collectively, these items under a
section form a checklist.

Items are never removed from checklists unless the check-mark is `I` or
`S` (case-insensitive).

Checklists are never re-ordered, and new checklists appear below
existing checklists (and above the `Ignore:` section).
Checklist items are also never re-ordered, unless a special check-mark
is used which mandates this. New checklist items appear below existing
items.

#### Check-marks

There are two kinds of special check-mark (case insensitive):

* `I`: Ignore the filename in future runs, and delete from this
  checklist as soon as possible. Mnemonic: "Ignore".
* `S`: Ignore the filename in future runs, delete from this checklist as
  soon as possible, and create an entirely new checklist from this
  filename. Only really makes sense for directories. Mnemonic: "Split",
  "Search", or "Subdirectory".

It is not guaranteed that these will be the only special kinds of
check-marks. Since this script is mostly personal to me, I don't feel
obliged to make any special guarantees. As my gift to you, check-marks
beginning with `#` (the hash character) will never be considered special
in any way.

Check-marks which are not special will not have any special treatment
applied. They will be preserved exactly between runs of this tool.

Example file
------------

Here is an unrealistic, fantastical example of a file to be processed by
this software:

```
From:
- ~/docs
- ~/videos/anime/*

PDFs and stuff = /home/me/docs:
[S] books
[ ] hyperloop_alpha-20130812.pdf
[X] lf_pub_who_writes_linux_2013.pdf
[ ] redditfoodpdf.pdf
[i] university research project

= /home/me/videos/anime/misc:
[# TAKE THESE SUGGESTIONS #] lainchan__w_eeb_recommended_media.txt

= /home/me/videos/anime/action:
[X] Overlord
[X] Tengen Toppa Gurren Lagann

= /home/me/videos/anime/qt:
[ ] Gochuumon wa Usagi Desu ka
[X] Kiniro Mosaic

= /home/me/videos/anime/comedy:
[ ] Jinrui wa Suitai Shimashita
[X] Nichijou

Ignore:
- /home/me/docs/books/reading-list.txt
```

It is unrealistic in that it is far more organised and clean than I
could ever reasonably expect, and if you only plan to watch 6 anime
series then you really need to step up your game.

In this example, the `books` directory (under /home/me/docs) is about to
be removed from the "PDFs and stuff" checklist and re-created as a
checklist in its own right. The `university research project` directory
is about to disappear and be thrown into the `Ignore:` list. Everything
else is going to stay as-is, unless more files have been created inside
directories managed by checklists already, or more directories have been
created matching the glob `~/videos/anime/*`.

Dependencies
------------

* `perl` 5.16
* The `enum` module (get it from CPAN)
    * This dependency could be easily patched out. It does something
      trivial.

Limitations
-----------

To avoid the need for complex escaping and such, pathnames will be
entirely ignored if they:

* Contain newlines
* Have trailing whitespace
* Have leading whitespace

I hope you sympathise.
