FROM openbao/openbao:2.3.2

COPY --chown=openbao:openbao \
    build/vault/plugins/vault-plugin-secrets-nats-linux-amd64 \
    /etc/vault/vault_plugins/vault-plugin-secrets-nats

RUN (sha256sum /etc/vault/vault_plugins/vault-plugin-secrets-nats | cut -d' ' -f1) \
    > /etc/vault/vault_plugins/vault-plugin-secrets-nats.sha256 && \
    chown openbao:openbao /etc/vault/vault_plugins/vault-plugin-secrets-nats.sha256
