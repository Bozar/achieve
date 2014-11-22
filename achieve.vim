" daily achievement "{{{1

" Last Update: Nov 22, Sat | 09:16:02 | 2014

" load & cpoptions "{{{2

if !exists('g:Loaded_Achieve')

    let g:Loaded_Achieve = 0

endif

if g:Loaded_Achieve > 0

    finish

endif

let g:Loaded_Achieve = 1

let s:Save_cpo = &cpoptions
set cpoptions&vim

 "}}}2
" variables "{{{2

" script {{{3

let s:Date = '^\d\{1,2} 月 \d\{1,2} 日'
let s:Date .= ' {\{3}\d$'

let s:Today = '\d\{1,2}\( 日\)'

let s:Buffer = '^缓冲区 {\{3}\d$'

let s:Count = '\(\d\{1,2}\)\(\.\)'
let s:Time = '\(\d\{2,3}\)'

let s:Progress = s:Count
let s:Progress .= s:Time

let s:notProgress = '\(' . s:Progress . '\)\@<!$'

let s:Seperator = '，'
let s:Initial = s:Seperator . '1.30'

let s:BulletBefore = '    \*'
let s:BulletAfter = '    \~'

let s:BulletOR = '\(' . s:BulletBefore . '\)\|'
let s:BulletOR .= '\(' . s:BulletAfter . '\)'

let s:TaskFoldLevel = 2

let s:Mark = '###LONG_PLACEHOLDER_FOR_ACHIEVE_###'

let s:firstToLast = 'a:firstline .'
let s:firstToLast .= " ',' ."
let s:firstToLast .= ' a:lastline'

 "}}}3
" global "{{{3

if !exists('g:KeyDone_Achieve')

    let g:KeyDone_Achieve = ''

endif

if !exists('g:KeyDay_Achieve')

    let g:KeyDay_Achieve = ''

endif

if !exists('g:KeyMove_Achieve')

    let g:KeyMove_Achieve = ''

endif

if !exists('g:KeyTask_Achieve')

    let g:KeyTask_Achieve = ''

endif

if !exists('g:AutoLoad_Achieve')

    let g:AutoLoad_Achieve = ''

endif

 "}}}3
 "}}}2
" functions "{{{2

function s:Done() range "{{{3

    if substitute(getline('.'),
    \ s:BulletBefore,'','') != getline('.')

        " undone (*) > done (~)

        execute eval(s:firstToLast) .
        \ 's/^' . s:BulletBefore . '/' .
        \ s:BulletAfter . '/'

    elseif substitute(getline('.'),
    \ s:BulletAfter,'','') != getline('.')

        " done (~) > undone (*)

        execute eval(s:firstToLast) .
        \ 's/^' . s:BulletAfter . '/' .
        \ s:BulletBefore . '/'

    endif

endfunction "}}}3

function s:AnotherDay() "{{{3

    let l:cursor = getpos('.')

    " check fold head

    call moveCursor#GotoFoldBegin()

    if substitute(getline('.'),
    \ s:Date,'','') == getline('.')

        echo 'ERROR:' . " '" . s:Date . "'" .
        \ ' not found!'

        call setpos('.',l:cursor)
        return

    else

        call setpos('.',l:cursor)

    endif

    " insert new lines for another day

    call MoveFoldMarker(2)

    " fix substitution errors on rare occasions:
    " the second day in a month
    " in which case both }2 will be changed

    'l-1
    call search('}\{3}' . s:TaskFoldLevel . '$',
    \ 'cW')
    mark l

    'h,'l-1yank
    'h-2mark z
    'zput

    " change date and foldlevel

    execute "'z+1s/" . s:Today  . '\@=/' .
    \ '\=submatch(0)+1/'

    call MappingMarker(1)
    call ChangeFoldLevel(2)

    'zdelete
    execute 'normal mh]zml'

    " substitute 'page 2-5' with 'page 6-'

    'h,'ls/\(\d\+-\)\@<=\(\d\+\)/\=submatch(0)+1/e
    'h,'ls/\d\+-\(\d\+\)/\1-/e

    " substitute done (~) with undone (*)

    execute "'h,'ls/^" . s:BulletAfter . '/' .
    \ s:BulletBefore . '/e'

    'h+2
    execute 'normal wma'

endfunction "}}}3

function s:MoveTask() range "{{{3

    let l:cursor = getpos('.')

    call moveCursor#GotoColumn1('w0','str')
    let l:top = getpos('.')

    if substitute(getline(a:firstline),
    \ '^' . s:BulletOR,'','') ==
    \ getline(a:firstline)

        call setpos('.',l:cursor)
        echo 'ERROR: Task line not found!'
        return

    endif

    " set new marker 'a' before moving today's
    " first task into buffer

    if substitute(getline(a:firstline - 2),
    \ s:Date,'','') != getline(a:firstline - 2)

        execute a:lastline . ' + 1'
        execute 'normal wma'

    endif

    " move tasks between buffer and today

    " re-set task bullet

    execute eval(s:firstToLast) .
    \ 's/^' . s:BulletAfter . '/' .
    \ s:BulletBefore . '/e'

    let l:fold = &foldenable

    execute a:firstline
    call moveCursor#GotoFoldBegin()

    " from today into buffer

    if substitute(getline('.'),
    \ s:Date,'','') != getline('.')

        execute eval(s:firstToLast) . 'delete'

        call search(s:Buffer,'bW')
        set nofoldenable
        +1put

    " from buffer into today

    elseif substitute(getline('.'),
    \ s:Buffer,'','') != getline('.')

        execute eval(s:firstToLast) . 'delete'

        call search(s:Date,'W')
        execute 'normal zjzk'
        set nofoldenable
        -2put

    endif

    let &foldenable = l:fold

    call setpos('.',l:top)
    execute 'normal zt'

    execute a:lastline
    execute 'normal w'

endfunction "}}}3

function s:TaskBar() range "{{{3

    " add new task progress bar

    if a:firstline == a:lastline

        execute a:firstline . 's/$/' . s:Initial .
        \ '/'

    endif

    " update task progress bar

    if a:firstline != a:lastline

        execute a:firstline
        call moveCursor#GotoColumn1('.','str')

        let l:error = 'ERROR: At least one task'
        let l:error .= ' contains no progression!'

        if search(s:notProgress,'c',a:lastline)

            echo l:error
            return

        endif

        " get first count

        let l:begin = substitute(
        \ getline(a:firstline),
        \ '^.\{-}' . s:Progress . '$','\1','')

        " delete old progress bar

        execute eval(s:firstToLast) .
        \ 's/' . s:Progress . '$//'

        let l:i = l:begin
        let l:j = l:begin * 30
        let l:lnum = a:firstline

        execute l:lnum

        while l:lnum <= a:lastline
            
            let l:str = l:i . '.' . l:j

            execute l:lnum . 's/$/\=l:str/'

            let l:i = l:i + 1
            let l:j = l:j + 30

            let l:lnum = l:lnum +1

        endwhile

    endif

endfunction "}}}3

function s:LoadScriptVars() "{{{3

    if g:KeyDone_Achieve != ''

        let s:KeyDone = g:KeyDone_Achieve

    else

        let s:KeyDone = '<enter>'

    endif

    if g:KeyDay_Achieve != ''

        let s:KeyDay = g:KeyDay_Achieve

    else

        let s:KeyDay = '<c-tab>'

    endif

    if g:KeyMove_Achieve != ''

        let s:KeyMove = g:KeyMove_Achieve

    else

        let s:KeyMove = '<tab>'

    endif

    if g:KeyTask_Achieve != ''

        let s:KeyTask = g:KeyTask_Achieve

    else

        let s:KeyTask = '<c-enter>'

    endif

endfunction "}}}3

function s:KeyMapModule(key,fun,mode) "{{{3

    " normal mode

    if substitute(a:mode,'n','','') != a:mode

        execute 'nnoremap <buffer> <silent>' .
        \ ' ' . a:key .
        \ ' :call <sid>' . a:fun . '()<cr>'

    endif

    " visual mode

    if substitute(a:mode,'v','','') != a:mode

        execute 'vnoremap <buffer> <silent>' .
        \ ' ' . a:key .
        \ ' :call <sid>' . a:fun . '()<cr>'

    endif

endfunction "}}}3

function s:KeyMapValue() "{{{3

    call <sid>LoadScriptVars()

    call <sid>KeyMapModule(
    \ s:KeyDone,'Done','nv')

    call <sid>KeyMapModule(
    \ s:KeyDay,'AnotherDay','n')

    call <sid>KeyMapModule(
    \ s:KeyMove,'MoveTask','nv')

    call <sid>KeyMapModule(
    \ s:KeyTask,'TaskBar','nv')

endfunction "}}}3

function s:AutoCommand() "{{{3

    if g:AutoLoad_Achieve == ''

        return

    endif

    execute 'autocmd BufRead,BufNewFile' .
    \ ' ' . g:AutoLoad_Achieve .
    \ ' call <sid>KeyMapValue()'

endfunction "}}}3

 "}}}2
" commands "{{{2

autocmd VimEnter * call <sid>AutoCommand()

 "}}}2
" cpotions "{{{2

let &cpoptions = s:Save_cpo
unlet s:Save_cpo

 "}}}2
 "}}}1
