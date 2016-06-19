# README #

The BibspaceBibtexToHtml is a wrapper of:
* Text::BibTeX::BibStyle (authored by  Mark Nodine [CPAN](http://search.cpan.org/~nodine/Text-BibTeX-BibStyle-0.03/)) plus several custom fixes and optimizations
* good old ocaml-based [bibtex2html](https://www.lri.fr/~filliatr/bibtex2html/) including some very dirty legacy custom fixes

## Short description ##

The main aim of BibspaceBibtexToHtml was to replace `bibtex2html` with `something different`. `something different` should produce `bbl` BibTeX output based on the provided `bst` files and do not depend on the non-Perl `bibtex2html` program. `Text::BibTeX::BibStyle` version 0.03 provided partial solution but the code is abandoned since year 2007.

From the original code of `Text::BibTeX::BibStyle`, I changed the following:
* allow to pass the contents of a `bib` entry in a variable instead of a path to file (the old method is also possible),
* allow to pass the path to a `bst` file instead of specifying a directory and file name,
* changed the function `execute` for run based either on bib files of the variable input
* several performance fixes (although there is still a lot to do in the performance context)
* disabled cross references (we don't need them and we want more performance)

## Limitations ##

The, so-called, *old_method* is very dirty and customized. Please don't use it. It is here just to make sure that the output of the *new method* is the same (or better) than the old one.

The *new method* fixes the HTML encoding for German and Polish diacritics characters. Supported are the following. German: äüöÄÜÖß, Polish: zażółć gęślą jaźń ZAŻÓŁĆ GĘŚLĄ JAŹŃ. 

**There is still a lot to do here!** Or just use something that properly decodes bibtex and encodes utf8 - I could not find such lib.


## How to use it? ##

Busy PhD students have no time to write docs :P Let the code be the doc, I prepared a demo in file `demo.pl`.

Sorry, this time, there are no tests. The code is still in early development and should be used with caution. It may be worth to give it a try as there are not many (no at all?) alternatives for Perl that consume *.bst* files to shape the bibtex output.

## Notes ##

Commenting out the following code in the bst file may hide some BibTeX warnings or errors. The HTML code should be generated correctly, but we give no guarantee.

```bst
% FUNCTION {presort}
% { type$ "book" =
%   type$ "inbook" =
%   or
%     'author.editor.sort
%     { type$ "proceedings" =
%         'editor.organization.sort
%         { type$ "manual" =
%             'author.organization.sort
%             'author.sort
%           if$
%         }
%       if$
%     }
%   if$
%   "    "
%   *
%   year field.or.null sortify
%   *
%   "    "
%   *
%   title field.or.null
%   sort.format.title
%   *
%   #1 entry.max$ substring$
%   'sort.key$ :=
% }
% 
% ITERATE {presort}
````