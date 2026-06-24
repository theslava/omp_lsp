FROM ubuntu:24.04

# run as root
RUN apt-get update && apt-get install -y \
    curl git ca-certificates ripgrep clangd \
    && rm -rf /var/lib/apt/lists/*

RUN sed -ie 's/ubuntu/slava/g' /etc/passwd* /etc/group*
RUN mv /home/ubuntu /home/slava

# Become slava user
USER slava:slava
ENV PATH="/home/slava/.local/bin:$PATH"

# OMP standalone binary
RUN curl -fsSL https://omp.sh/install | bash

CMD ["sleep", "infinity"]
