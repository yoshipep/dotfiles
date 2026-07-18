# Container environment

You are in a Docker container.

Don't install packages yourself. When one is missing, stop and tell the user which
package to install; they will `sudo apt install` it. Continue once it's in place.
