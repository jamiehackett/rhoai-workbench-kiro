# Custom RHOAI workbench image: official Code Server Data Science + Kiro CLI
#
# Base: registry.redhat.io catalog image matching RHOAI code-server-notebook:3.5
# (notebook build commit 47efb6c).
#
# Refresh the digest after a RHOAI upgrade:
#   oc get is code-server-notebook -n redhat-ods-applications \
#     -o jsonpath='{.spec.tags[?(@.name=="3.5")].from.name}{"\n"}'
# or:
#   podman pull registry.redhat.io/rhoai/odh-workbench-codeserver-datascience-cpu-py312-rhel9:<tag>
#   podman image inspect --format '{{.Digest}}' <image>

FROM registry.redhat.io/rhoai/odh-workbench-codeserver-datascience-cpu-py312-rhel9@sha256:45e35703144250c03b812ca381cd6dfcf3c023f7fe8bfeec28ba10f27ef73844

USER 1001
WORKDIR /opt/app-root/src

# Install into /opt/app-root/bin so the binary survives the workbench PVC mount at $HOME
# (/opt/app-root/src). Do not leave the only copy under $HOME.
RUN curl -fsSL https://cli.kiro.dev/install | bash \
    && install -m 0755 /opt/app-root/src/.local/bin/kiro-cli /opt/app-root/bin/kiro-cli \
    && /opt/app-root/bin/kiro-cli --version \
    && rm -rf /opt/app-root/src/.local/bin/kiro-cli /tmp/*

ENV PATH="/opt/app-root/bin:${PATH}"
