<!-- panvimdoc-ignore-start -->

cvs.nvim
========

NeoVim plugin to improve experience while working with CVS.

<!-- panvimdoc-ignore-end -->

Features
========

- UI for cvs log (Telescope)
- UI for cvs diff (fileset, Telescope)
- UI for cvs diff (2-way diff)
- UI for cvs annotate
- UI for cvs commit

Installation
============

Dependencies

- [Telescope](https://github.com/nvim-telescope/telescope.nvim)
- [plenary](https://github.com/nvim-lua/plenary.nvim)

Using [Packer](https://github.com/wbthomason/packer.nvim)

    use{
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

    :CVSLog [OPTIONS] [FILES OR DIRECTORIES]

<!-- panvimdoc-ignore-end -->
<!-- panvimdoc-include-comment
```vimdoc
`:CVSLog [OPTIONS] [FILES OR DIRECTORIES]`                           *:CVSLog*
``` -->

Will output log for file or directory, grouping changes by commits.

If no file or directory is passed will use current working directory to
fetch log (like `cvs log` command)

Possible options are:

- `-A author` to filter changes by author (multiple options possible)
- `-d date_range` to filter changes by date range (same syntax
  as `cvs log -d`)

Examples:

This will show changes in current working directory for last week:

    :CVSLog -d ">1 week ago"

This will show changes during July 2023 for files README.md and LICENSE

    :CVSLog -d 2023-07-01>2023-08-01 README.md LICENSE

This will show changes by mrchnk or nikolai older than 1 year in folder plugin

    :CVSLog -A mrchnk -A nikolai -d "<1 year ago" plugin/


