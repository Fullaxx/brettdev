# ------------------------------------------------------------------------------
# Pull base image
FROM ghcr.io/fullaxx/ubuntu-desktop:latest
LABEL author="Brett Kuskie <fullaxx@gmail.com>"

# ------------------------------------------------------------------------------
# Set environment variables
ENV DEBIAN_FRONTEND="noninteractive"
ENV TZ="UTC"
# VIRTUAL_ENV and PATH are BUILD-TIME settings: RUN steps that call python3/pip
# (here, or in Dockerfile.full, which builds FROM this image) get the venv rather
# than the system Python. They also reach PID 1 and `docker exec` shells, but NOT
# the VNC desktop session: /app/tiger.sh starts it with `sudo tigervncserver`, and
# sudo's env_reset/secure_path drop them. Runtime shells get them from
# conf/etc_bash_bashrc (appended to /etc/bash.bashrc). See PYTHON_VENV.md.
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# ------------------------------------------------------------------------------
# Install requirements.txt and scripts
COPY requirements.txt /install/requirements.txt
COPY scripts /install/scripts

# ------------------------------------------------------------------------------
# UnMinimize
RUN /install/scripts/unminimize.sh

# ------------------------------------------------------------------------------
# Install Firefox PPA
RUN /install/scripts/add_firefox_ppa.sh

# ------------------------------------------------------------------------------
# Install tools from ubuntu repo
RUN /install/scripts/add_dev_tools.sh

# ------------------------------------------------------------------------------
# Install fonts: glyph fallback, coding fonts, Nerd Font icons (see FONTS.md)
RUN /install/scripts/add_fonts.sh

# ------------------------------------------------------------------------------
# Install wallpaper scripts and configuration files
COPY bg/snowglobefluorescence1HDfree.jpg /usr/share/backgrounds/
COPY conf/menu.xml /usr/share/ubuntu-desktop/openbox/

# ------------------------------------------------------------------------------
# Adjust autostart
# RUN echo "\nhsetroot -center /usr/share/backgrounds/hardy_wallpaper_uhd.png" >>/usr/share/ubuntu-desktop/openbox/autostart
RUN echo "\nhsetroot -center /usr/share/backgrounds/snowglobefluorescence1HDfree.jpg" >>/usr/share/ubuntu-desktop/openbox/autostart
RUN echo "\n# Set Keyboard Rate\nxset r rate 195 35" >>/usr/share/ubuntu-desktop/openbox/autostart

# ------------------------------------------------------------------------------
# Bash setup: dot_bashrc (-> /root/.bashrc) colors the prompt; etc_bash_bashrc
# (-> /etc/bash.bashrc) sets the runtime environment for every interactive shell
# (venv, Go, Claude, bun on PATH) plus helpers -- see the header in that file
COPY conf/dot_bashrc conf/etc_bash_bashrc /usr/share/ubuntu-desktop/
RUN cat /usr/share/ubuntu-desktop/dot_bashrc >>/root/.bashrc
RUN cat /usr/share/ubuntu-desktop/etc_bash_bashrc >>/etc/bash.bashrc

# ------------------------------------------------------------------------------
# Add configuration files for bluefish, geany, terminology
ADD personalization.tar /

# ------------------------------------------------------------------------------
# Expose ports
EXPOSE 5901

# ------------------------------------------------------------------------------
# Define default command
CMD ["/app/app.sh"]
