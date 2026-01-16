set disassembly-flavor intel
set print demangle off
set print asm-demangle off
set max-value-size unlimited
unset env LINES
unset env COLUMNS

define dcore
  if $argc < 1
    printf "Usage: dcore <filename>\n"
    return
  end
  shell echo 0xff > /proc/$$/coredump_filter
  gcore $arg0
end
document dcore
Dumps a core file of the current debugging process
Usage: dcore <filename>
Example: dcore core_file
end

define printenvp
  if $argc < 1
    printf "Usage: printenvp <addr>\n"
  else
    set $envp = (char **)$arg0
    set $i = 0
    while $envp[$i] != 0
      printf "%s\n", $envp[$i]
      set $i = $i + 1
    end
  end
end
document printenvp
Print all environment variables from the given envp pointer
Usage: printenvp <addr>
Example: printenvp $rdx
end
