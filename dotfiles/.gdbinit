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

# GEF (installed to a stable filename by install_env.sh) and GEP.
# Sourced here rather than relying on the installers' own ~/.gdbinit edits,
# because installConfigDeploy copies this file over ~/.gdbinit and would clobber
# them. Guarded so this .gdbinit stays error-free on a box where GEF/GEP aren't
# installed (e.g. a config-only deploy with a system gdb) — same graceful-
# degradation idea as .zshrc.
python
import os, gdb
for _f in ("~/.gef-gdb.py", "~/.local/share/GEP/gdbinit-gep.py"):
    _p = os.path.expanduser(_f)
    if os.path.exists(_p):
        gdb.execute("source " + _p)
end
