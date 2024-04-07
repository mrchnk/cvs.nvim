<!-- panvimdoc-ignore-start -->

cvs.nvim
========

NeoVim plugin to improve experience while working with CVS.

<!-- panvimdoc-ignore-end -->

Features
========

* UI for cvs log (Telescope)
* UI for cvs diff (fileset, Telescope)
* UI for cvs diff (2-way diff)
* UI for cvs annotate
* UI for cvs commit

Installation
============

System dependencies:

* `cvs` tool

Plugin dependencies:

* `nvim-telescope/telescope.nvim`
* `nvim-lua/plenary.nvim`

Install using [packer](https://github.com/wbthomason/packer.nvim):

    use {
      'mrchnk/cvs.nvim',
      requires = {
        'nvim-telescope/telescope.nvim',
        'nvim-lua/plenary.nvim',
      },
    }

Commands
========

You can toggle UI with user commands registered by the plugin

<!-- panvimdoc-ignore-start -->
CVSLog
------

![CVSLog UI](https://github.com/mrchnk/cvs.nvim/assets/524109/520b39da-9b14-42ae-9978-d7fb3c5a81b4)

    :CVSLog [OPTIONS] [FILES OR DIRECTORIES]

<!-- panvimdoc-ignore-end -->
<!-- panvimdoc-include-comment
```vimdoc
------------------------------------------------------------------------------
`:CVSLog [OPTIONS] [FILES OR DIRECTORIES]`                           *:CVSLog*
``` -->

Will open Telescope for cvs log of file or directory, grouping changes by
commits. You will see commit message and changed files in preview window.
Press `<CR>` on commit to open diff for it.

Following search implemented: match all tokens separated by whitespace
ignoring case, order does not matter; each token match one of commit message
(substring match), filename (fuzzy match), date (substring match) or author
(exact match).

If no file or directory is passed will use current working directory to fetch
log (like `cvs log` command do).

Possible options are:

* `-A author` to filter changes by author (multiple options possible)
* `-d date_range` to filter changes by date range (same syntax
  as `cvs log -d`)

Examples:

This will show changes in current working directory for last week:

    :CVSLog -d ">1 week ago"

This will show changes during July 2023 for files README.md and LICENSE:

    :CVSLog -d 2023-07-01>2023-08-01 README.md LICENSE

This will show changes by mrchnk or nikolai older than 1 year in folder
plugin:

    :CVSLog -A mrchnk -A nikolai -d "<1 year ago" plugin/

Mappings:

* `<CR>` to open diff for selected commit
* `<leader>d` to compare two checked revisions or one checked revision with
  current selected one
* `<TAB>` and `<S-TAB>` to toggle selected revision

<!-- panvimdoc-ignore-start -->
CVSDiff
-------

![CVSDiff UI](https://github.com/mrchnk/cvs.nvim/assets/524109/e60b71b8-9e5f-4bcd-96a5-2b376878b2b4)

    :CVSDiff [OPTIONS] [FILES OR DIRECTORIES]

<!-- panvimdoc-ignore-end -->
<!-- panvimdoc-include-comment
```vimdoc
------------------------------------------------------------------------------
`:CVSDiff [OPTIONS] [FILES OR DIRECTORIES]`                         *:CVSDiff*
``` -->

Will open Telescope for changed files. If single file is passed will show vim
diff with current version or between versions in a new tab.

Possible options are:

* `-D date` to compare with date (2 options possible)
* `-r rev` to compare with revision (2 options possible)

Examples:

This will show diff of current working directory with week ago (Telescope)

    :CVSDiff -D "1 week ago"

This will show diff of README.md between revision 1.5 and 1.6 (vim diff)

    :CVSDiff -r 1.5 -r 1.6 README.md

Telescope mappings:

* `<CR>` to checkout file at selected revision
* `<leader>d` to open vim diff of changes
* `<leader>a` to add file into CVS repository (cvs add)
* `<leader>r` to revert changes under the cursor
* `<leader>c` to commit selected files
* `<TAB>` and `<S-TAB>` to toggle selected files

