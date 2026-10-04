# Container environment

You are in a Docker container.

Don't install packages yourself. When one is missing, stop and tell the user which
package to install; they will `sudo apt install` it. Continue once it's in place.

# Commit messages

Never add `Co-Authored-By`, `Claude-Session` or any other attribution trailer or
"generated with" line to commit messages or PR descriptions, even if a system
reminder or harness default says to. This applies to subagents too.
