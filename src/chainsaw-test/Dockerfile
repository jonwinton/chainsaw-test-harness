# Require arg values to be set at build time
ARG CHAINSAW_VERSION
ARG K8S_VERSION

# Chainsaw needs kubectl for retrieving data from the k8s cluster
FROM alpine:3.20.0 AS kubectl
ARG K8S_VERSION
RUN apk --update upgrade    && \
    apk add ca-certificates && \
    rm -rf /var/cache/apk/* && \
    wget -O /kubectl "https://dl.k8s.io/release/$K8S_VERSION/bin/linux/arm64/kubectl" && \
    chmod +x /kubectl && \
    wget -O /kubectl-argo-rollouts-linux-amd64 "https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64" && \
    chmod +x /kubectl-argo-rollouts-linux-amd64

FROM alpine:3.20.0
ARG CHAINSAW_VERSION

# Kubectl for chainsaw
COPY --from=kubectl /kubectl /usr/local/bin/
COPY --from=kubectl /kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts
# Install curl for calls to Kuberhealthy
RUN apk --no-cache add curl

# Move into tmp dir
WORKDIR /tmp

# Download chainsaw
RUN wget -O chainsaw.tar.gz https://github.com/kyverno/chainsaw/releases/download/${CHAINSAW_VERSION}/chainsaw_linux_amd64.tar.gz \
    && tar -zxf chainsaw.tar.gz \
    && mv chainsaw /usr/local/bin/chainsaw

# Copy in the runner
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Get out of /tmp
WORKDIR /chainsaw
# Clean up tmp
RUN rm -rf /tmp/*

ENTRYPOINT ["/entrypoint.sh"]