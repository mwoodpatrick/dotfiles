" ====================================================================
" General Settings
" ====================================================================

" Required for plugins and advanced features
set nocompatible

" Enable filetype-specific settings and plugin loading
filetype plugin indent on

" Use 'C' style line numbering relative to the cursor line
set number
set relativenumber

" Highlighting the current line
set cursorline

" Set case-insensitive searching
set ignorecase

" When searching, if there are capital letters in the search term,
" make the search case-sensitive.
set smartcase

" Highlight all matches while searching
set hlsearch

" Incrementally highlight matches as you type
set incsearch

" Set the display width of a tab character to 4 spaces
set tabstop=4

" Set the number of spaces to use for auto-indent and shifting
set shiftwidth=4

" Use spaces instead of tabs (Recommended for consistent code)
set expandtab

" Smart indentation for various file types
set autoindent
set smartindent

" Set status line to always show
set laststatus=2

" Show command in the status line
set showcmd

" Show current mode in the status line
set showmode

" Automatically wrap lines that exceed the text width (default 80)
set wrap
set textwidth=80

" For persistent undo history
set undofile
set undodir=~/.vim/undodir

" ====================================================================
" Visual & Appearance Settings (Good for GVim)
" ====================================================================

" Enable mouse support in all modes (handy in terminal Vim too)
set mouse=a

" Set a default color scheme (choose one you like, or leave blank)
colorscheme desert

" Enable syntax highlighting
syntax on

" Persistent folding when opening a file
set foldmethod=syntax
set foldlevel=99

" Set the background (dark is usually better for code)
set background=dark

" ====================================================================
" Backup & Swap Settings
" ====================================================================

" Store backup and swap files in a dedicated directory
set backupdir=~/.vim/backup
set directory=~/.vim/swap

" Disable creation of backup files
set nobackup
" Disable creation of swap files (Use only if you trust undofile!)
set noswapfile

" ====================================================================
" Key Mappings (Optional, but useful)
" ====================================================================

" Toggle highlighting for search results (Leader key + h)
nnoremap <leader>h :nohlsearch<CR>

" Convenient mapping for saving
nnoremap <leader>w :w<CR>

" Clear trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e
