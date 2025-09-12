# ------------------------------------------------------------------------------
# Pull base image
FROM fullaxx/ubuntu-desktop
LABEL author="Brett Kuskie <fullaxx@gmail.com>"

# ------------------------------------------------------------------------------
# Set environment variables
ENV DEBIAN_FRONTEND="noninteractive"
ENV TZ="Etc/Zulu"

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
# Install qlibc
RUN /install/scripts/add_qlibc.sh

# ------------------------------------------------------------------------------
# Install lazygit
RUN /install/scripts/add_lazygit.sh

# ------------------------------------------------------------------------------
# Install btop++
RUN /install/scripts/add_btop.sh

# ------------------------------------------------------------------------------
# Install git delta
RUN /install/scripts/add_git_delta.sh

# ------------------------------------------------------------------------------
# Install websocat
RUN /install/scripts/add_websocat.sh

# ------------------------------------------------------------------------------
# Install Draw.io
RUN /install/scripts/add_drawio_desktop.sh

# ------------------------------------------------------------------------------
# (DISABLED) Install kaitai-struct compiler and visualizer
# RUN /install/scripts/add_kaitai_struct.sh

# ------------------------------------------------------------------------------
# Install Chrome
RUN /install/scripts/add_chrome.sh

# ------------------------------------------------------------------------------
# Install VSCode
RUN /install/scripts/add_vscode.sh

# ------------------------------------------------------------------------------
# (DISABLED) Install libcorrect
# RUN /install/scripts/add_libcorrect.sh

# ------------------------------------------------------------------------------
# (DISABLED) Install libaff3ct.sh
# RUN /install/scripts/add_libaff3ct.sh

# ------------------------------------------------------------------------------
# (DISABLED) Install GnuRadio
# RUN /install/scripts/add_gnuradio.sh
# RUN /install/scripts/add_gnuradio_ppa.sh

# ------------------------------------------------------------------------------
# (DISABLED) Install Eclipse
# RUN ECLPKG="CPP" /app/scripts/install_eclipse.sh

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
# Adjust bash prompt
COPY conf/dot_bashrc /usr/share/ubuntu-desktop/
RUN cat /usr/share/ubuntu-desktop/dot_bashrc >>/root/.bashrc

# ------------------------------------------------------------------------------
# Add configuration files for bluefish, geany, terminology
ADD personalization.tar /

# ------------------------------------------------------------------------------
# Expose ports
EXPOSE 5901

# ------------------------------------------------------------------------------
# Define default command
CMD ["/app/app.sh"]
