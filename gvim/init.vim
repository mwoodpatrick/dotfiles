"When changing the value also check these options: 
"'shelltype', 'shellpipe', 'shellslash' 'shellredir', 
"'shellquote', 'shellxquote' and 'shellcmdflag'.
syntax enable
" Set the initial window size
" Query using
"   echo &columns : Prints the width of the entire Vim frame in characters.
"   echo &lines : Prints the height of the entire Vim frame in lines.
" set columns=100
" set lines=26
" work around for ensuring line & character position are reported e.g. line 230 of 2756 --8%-- col 14
" http://vimdoc.sourceforge.net/htmldoc/editing.html#CTRL-G
" http://stackoverflow.com/questions/526858/how-do-i-make-vim-do-normal-bash-like-tab-completion-for-file-names
" make sure ruler is not set

" Set columns and lines ONLY if running in a GUI
" Displays in xterm
" echo "VIMRUNTIME="..$VIMRUNTIME 
if has("gui_running")
  " echo "gui running"
  set columns=120
  set lines=20
endif

set nocompatible
set wildmode=longest,list,full
set wildmenu
set shell=bash
set ssl
set ts=4
set makeprg=msdev
set expandtab
set autoindent
set autowrite
set incsearch
set smartcase 
set ignorecase
set number
set relativenumber
behave xterm
set tags=$doswt\tags
set selectmode=mouse
set errorformat=%f(%l)\ :\ %m
map <F6> :nohls <CR>

" ensure we can see underscores 
" https://stackoverflow.com/questions/21964631/gvim-display-underscore-as-space
set linespace=2

" ensure undolevels is positive otherwise gvim will report that its at its oldest change
set undolevels=9999

" enable persistent-undo
set undofile   " Maintain undo history between sessions
set undodir=~/.vim/undodir

function! DoMake(target)
   echo "Building target ".a:target
   if a:target == "mdd" 
    cd $doswt/hw/nvdiag/multidiag
    pwd
   elseif a:target == "b"
    echoerr "Unable to write buffer!"
    return
   else
    echoerr "unknown target!"
   endif
endfunction

:com -nargs=* Mk call DoMake(<f-args>)

if has("gui_running")
"source $VIMRUNTIME/vimrc_example.vim
source $VIMRUNTIME/mswin.vim
"nnoremap @pfa       :!p4 add %<CR>:e<CR>
"nnoremap @pfe       :!p4 edit %<CR>:e<CR>
"nnoremap @pfd       :!p4 diff %<CR>
com -nargs=1 -bang -complete=file Pfa :!p4 add %<CR>:e<CR>
com -nargs=1 -bang -complete=file Pfe :!p4 edit %<CR>:e<CR>
com -nargs=1 -bang -complete=file Pfd :!p4 !p4 diff %<CR>
endif

31amenu C/C++.transform\ enum2Stringtab :s#[ ]*\\(\\w\\+\\)#/* \\1 */ "\\1"#<CR>o};<Esc>uOstatic const char* const Names[] = {<Esc><CR>:noh<CR>
31vmenu C/C++.transform\ enum2Stringtab :s#[ ]*\\(\\w\\+\\)#/* \\1 */ "\\1"#<CR>o};<Esc>uOstatic const char* const Names[] = {<Esc><CR>:noh<CR>

31amenu C/C++.transform\ enum2String :s#[ ]*\\(\\w\\+\\)#/* \\1 */ "\\1"#<CR>o}<Esc>:noh<CR>
31vmenu C/C++.transform\ enum2String :s#[ ]*\\(\\w\\+\\)#/* \\1 */ "\\1"#<CR>o}<Esc>:noh<CR>

function! Enum2Array()
    exe "normal! :'<,'>g/^\\s*$/d\n"
    exe "normal! :'<,'>s/\\(\\s*\\)\\([[:alnum:]_]*\\).*/\\1[\\2] = \"\\2\",/\n"
    normal `>
    exe "normal a\n};\n"
    normal `<
    exe "normal iconst char *[] =\n{\n"
    exe ":'<,'>normal ==" " try some indentation
    normal `< " set the cursor at the top
endfunction
