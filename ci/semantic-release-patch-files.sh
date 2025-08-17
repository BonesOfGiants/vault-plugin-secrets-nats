#!/bin/sh
set -e
NEXTVERSION=$1
for file in build/openbao/plugins/openbao-plugin-secrets-nats-*; do
  sha256sum $file > $file.sha256
    # this is to retain backward compatibility with the old naming convention
    if echo "$file" | grep -q "amd64"; then
        cp $file ./build/openbao/plugins/openbao-plugin-secrets-nats
        cp $file.sha256 build/openbao/plugins/openbao-plugin-secrets-nats.sha256
    fi
done
# only use x86 for the README.md and dev/manifests/openbao/openbao.yaml
export SHA256SUM=$(cat build/openbao/plugins/openbao-plugin-secrets-nats.sha256 | cut -d ' ' -f1)
sed -i "s#sha256: .*#sha256: ${SHA256SUM}#g" README.md
sed -i "s#image: ghcr.io/bonesofgiants/openbao-plugin-secrets-nats/openbao-with-nats-secrets:.*#image: ghcr.io/bonesofgiants/openbao-plugin-secrets-nats/openbao-with-nats-secrets:${NEXTVERSION}#g" README.md
