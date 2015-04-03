" daily achievement "{{{1
" Last Update: Apr 03, Fri | 15:37:41 | 2015

" variables "{{{2

" script "{{{3

let s:Date = '^\d\{1,2} 月 \d\{1,2} 日'
let s:Date .= ' {\{3}\d$'

let s:Today = '\d\{1,2}\( 日\)'

let s:Buffer = '^缓冲区 {\{3}\d$'

let s:Seperator = '，'

let s:Initial = s:Seperator . '1.30'

let s:Count = '\(\d\{1,2}\)\(\.\)'
let s:Time = '\(\d\{2,3}\)'

let s:Progress = s:Count
let s:Progress .= s:Time

let s:notProgress = '\(' . s:Seperator
let s:notProgress .= s:Progress . '\)\@<!$'

let s:BulletBefore = '    \*'
let s:BulletAfter = '    \~'

let s:BulletOR = '\(' . s:BulletBefore . '\)\|'
let s:BulletOR .= '\(' . s:BulletAfter . '\)'

let s:TaskFoldLevel = 2

let s:Mark = '###LONG_PLACEHOLDER_FOR_ACHIEVE_###'

let s:errorPro = 'ERROR: Line' . ' '
let s:errorGress = ' contains no progression!'

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
    call moveCursor#GotoFoldBegin()
    if substitute(getline('.'),
    \ s:Date,'','') ==# getline('.')
        echo 'ERROR:' . " '" . s:Date . "'" .
        \ ' not found!'
        call setpos('.',l:cursor)
        return
    else
        call setpos('.',l:cursor)
    endif

    let l:line = line('w0')
    let &foldlevel = 20

    " change old fold level
    normal! [zV]zy]zp]z
    if getline(line('.')-1) =~# '\v\}{3}2$'
        normal! k
    endif
    s/2$/3/
    normal! [z
    s/2$/3/
    normal! k[z

    " change new date
    execute "s/" . s:Today  . '\@=/' .
    \ '\=submatch(0)+1/'

    " substitute 'page 2-5' with 'page 6-'
    mark j
    normal! ]z
    mark k
    'j,'ks/\(\d\+-\)\@<=\(\d\+\)/\=submatch(0)+1/e
    'j,'ks/\d\+-\(\d\+\)/\1-/e

    " substitute done (~) with undone (*)
    execute "'j,'ks/^" . s:BulletAfter . '/' .
    \ s:BulletBefore . '/e'

    'j+2
    execute 'normal wma'
    let &foldlevel = 2
    execute l:line
    normal! zt
    'a

endfunction "}}}3

function s:MoveTask() range "{{{3

    let l:cursor = getpos('.')

    execute line('w0')
    execute 'normal! 0'
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
        execute 'normal! 0'

        if search(s:notProgress,'c',a:lastline)

            let l:error = s:errorPro . line('.')
            let l:error .= s:errorGress

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

function s:TimeSpent() "{{{3

    " check register pattern

    if @" == '' || search(@",'w') == 0

        echo 'ERROR: @" not found!'

        return

    endif

    " check task progress bar

    let l:register = @"

    let l:taskCheck = l:register . '.*'
    let l:taskCheck .= s:notProgress

    if search(l:taskCheck,'w')

        let l:error = s:errorPro . line('.')
        let l:error .= s:errorGress

        echo l:error

        return

    endif

    " delete everything EXCEPT s:Count

    execute 'g!/' . l:register . '/delete'

    execute '%s/^.*' . s:Seperator . s:Count .
    \ s:Time . '$/\1/'

    " check broken progression, such as: 1, 2, 4

    let l:lineNr = 1

    while l:lineNr <= line('$') - 1

        execute l:lineNr

        let l:i = getline('.')
        let l:j = getline(line('.') + 1)

        if l:j != l:i + 1 && l:j != 1

            let l:search = l:register . '.*' .
            \ l:i . '.' . l:i * 30

            let @/ = l:search

            let l:remind = 'Type n to search'
            let l:remind .= " '" . l:search . "'"

            undo

            echo 'ERROR: Progression broken!'
            echo l:remind

            return

        endif

        let l:lineNr = l:lineNr + 1

    endwhile

    " find max count, then delete smaller counts
    " in a group, such as:
    " [1], [2], 3; [1], [2], [3], 4

    let l:max = max(getline(1,'$'))
    let l:keep = 2

    while l:keep <= l:max

        let l:delete = l:keep - 1

        execute 'g/^' . l:keep . '$/-1s/' .
        \ '^' . l:delete . '$/' . s:Mark . '/'

        let l:keep = l:keep + 1

    endwhile

    if search(s:Mark,'w')

        execute 'g/' . s:Mark . '/delete'

    endif

    " sum up and calculate time

    let l:lineNr = 1
    let l:sum = 0

    while l:lineNr <= line('$')

        execute l:lineNr

        let l:sum = l:sum + getline('.')

        let l:lineNr = l:lineNr + 1

    endwhile

    let l:spent = l:sum / 2.0

    let l:time = 'Time spent:'
    let l:time .= ' ' . string(l:spent)
    let l:time .= ' hour(s).'

    echo l:time

endfunction "}}}3

function s:KeyMapScriptVar() "{{{3

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

    call <sid>KeyMapScriptVar()

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

    "execute 'autocmd BufRead,BufNewFile' .
    execute 'autocmd BufEnter,BufNewFile' .
    \ ' ' . g:AutoLoad_Achieve .
    \ ' call <sid>KeyMapValue()'

endfunction "}}}3

"}}}2
" commands "{{{2

autocmd VimEnter * call <sid>AutoCommand()

if !exists(':AchTimeSpent')

    command AchTimeSpent call <sid>TimeSpent()

endif

"}}}2
"}}}1
