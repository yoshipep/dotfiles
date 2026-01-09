" ============================================================================
" FUNCTIONS
" ============================================================================

function! AddHeaderGuards()
    " Get the filename without extension
    let l:filename = expand('%:t:r')
    let l:guard = toupper(l:filename)
    " Insert the header guard at the top of the file
    execute 'normal! gg'
    call append(0, '#ifndef ' . l:guard . '_H_')
    call append(1, '#define ' . l:guard . '_H_')
    call append(2, '')
    call append('$', '#endif // ' . l:guard . '_H_')
endfunc

function! DetectIndentation()
    " Skip if buffer is empty or very small
    if line('$') < 5
        return
    endif

    " Count lines with leading tabs vs spaces
    let l:tab_count = 0
    let l:space_count = 0
    let l:space_indent_sizes = {}

    " Sample up to 200 lines for performance
    let l:max_lines = min([line('$'), 200])

    for l:lnum in range(1, l:max_lines)
        let l:line = getline(l:lnum)

        " Skip empty lines and lines without indentation
        if l:line =~ '^\s*$' || l:line !~ '^\s'
            continue
        endif

        " Check if line starts with tab
        if l:line =~ '^\t'
            let l:tab_count += 1
        " Check if line starts with spaces
        elseif l:line =~ '^ '
            let l:space_count += 1

            " Detect space indent width (2, 4, or 8 spaces)
            let l:indent = matchstr(l:line, '^ \+')
            let l:indent_len = len(l:indent)

            " Track indent sizes
            if l:indent_len > 0
                let l:space_indent_sizes[l:indent_len] = get(l:space_indent_sizes, l:indent_len, 0) + 1
            endif
        endif
    endfor

    " If we found indented lines, adjust settings
    if l:tab_count > 0 || l:space_count > 0
        " Use tabs if tabs are more common
        if l:tab_count > l:space_count
            setlocal noexpandtab
            setlocal tabstop=8
            setlocal shiftwidth=8
        " Use spaces if spaces are more common
        else
            setlocal expandtab

            " Detect the most common indent width
            let l:common_width = 4  " default
            let l:max_occurrences = 0

            for [l:width, l:count] in items(l:space_indent_sizes)
                " Check for common widths: 2, 4, 8
                if (l:width == 2 || l:width == 4 || l:width == 8) && l:count > l:max_occurrences
                    let l:common_width = l:width
                    let l:max_occurrences = l:count
                endif
            endfor

            execute 'setlocal tabstop=' . l:common_width
            execute 'setlocal shiftwidth=' . l:common_width
            execute 'setlocal softtabstop=' . l:common_width
        endif
    endif
endfunc
