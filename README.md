# Kiro + Code Server custom workbench

Custom OpenShift AI (RHOAI) workbench image based on the official Red Hat Code
Server Data Science image, with AWS Kiro CLI (`kiro-cli`) installed to
`/opt/app-root/bin` so it survives the workbench home PVC mount.

| Item | Value |
|------|--------|
| Base image | `registry.redhat.io/rhoai/odh-workbench-codeserver-datascience-cpu-py312-rhel9` |
| Pinned digest (RHOAI 3.5 / `47efb6c`) | `sha256:45e35703144250c03b812ca381cd6dfcf3c023f7fe8bfeec28ba10f27ef73844` |
| ImageStream name | `kiro-codeserver` |
| Tag | `0.1.0` (also exposed as `latest`) |
| Display name | `Code Server \| Data Science + Kiro \| CPU \| Python 3.12` |
| Registration namespace | `redhat-ods-applications` (cluster-wide) |

## Prerequisites

- Pull access to `registry.redhat.io` (Red Hat pull secret)
- `podman` **or** permission to run OpenShift Builds in a project
- `oc` (for ImageStream registration or the BuildConfig path)
- OpenShift AI / cluster admin rights to register a cluster-wide workbench image
  (ImageStreams in `redhat-ods-applications`, or **Settings → Workbench images → Import**)

## Quick start (recommended)

Build with podman, push to a registry your cluster can pull, then import via the
RHOAI dashboard.

```bash
podman login registry.redhat.io
podman build -t kiro-codeserver:0.1.0 -f Containerfile .
podman push kiro-codeserver:0.1.0 <your-registry>/kiro-codeserver:0.1.0
```

1. Open **Settings → Workbench images → Import workbench image**
2. Point at `<your-registry>/kiro-codeserver:0.1.0`
3. Set the display name to: `Code Server | Data Science + Kiro | CPU | Python 3.12`
4. Confirm the image appears under cluster workbench images (available in every project)

## Optional: build with OpenShift BuildConfig

Use this if you prefer an in-cluster binary build instead of podman.

```bash
export BUILD_NAMESPACE=<your-build-project>
oc project "$BUILD_NAMESPACE"

# Ensure the build SA can pull registry.redhat.io (link the global pull secret if needed).
envsubst '${BUILD_NAMESPACE}' < imagestream-build.yaml | oc apply -f -
envsubst '${BUILD_NAMESPACE}' < buildconfig.yaml | oc apply -f -
oc start-build kiro-codeserver -n "$BUILD_NAMESPACE" --from-dir=. --follow

export IMAGE_REF="image-registry.openshift-image-registry.svc:5000/${BUILD_NAMESPACE}/kiro-codeserver:0.1.0"
```

`buildconfig.yaml` does **not** override `FROM`; the Containerfile digest is the source of truth.

## Register cluster-wide via ImageStream

Prefer the dashboard Import path above when possible. Use this if you manage
ImageStreams directly.

```bash
# IMAGE_REF = image you built (internal registry, Quay, etc.)
export IMAGE_REF='image-registry.openshift-image-registry.svc:5000/<build-ns>/kiro-codeserver:0.1.0'
# or: export IMAGE_REF='quay.io/<org>/kiro-codeserver:0.1.0'

envsubst '${IMAGE_REF}' < imagestream.yaml | oc apply -f -
oc get imagestream kiro-codeserver -n redhat-ods-applications
oc get imagestream kiro-codeserver -n redhat-ods-applications \
  -o jsonpath='{.metadata.annotations.opendatahub\.io/notebook-image-name}{"\n"}{.metadata.labels.opendatahub\.io/notebook-image}{"\n"}'
```

Requires create/update permission on ImageStreams in `redhat-ods-applications`.

## Verify in a workbench

1. Create or edit a workbench in any data science project
2. Select **Code Server | Data Science + Kiro | CPU | Python 3.12**
3. In a terminal:

```bash
kiro-cli --version
kiro-cli login --use-device-flow
kiro-cli
```

Kiro authentication is per-user at runtime. Only the CLI binary is baked into the image.

## Notes

- **Unsupported custom image.** Red Hat does not support the contents of customer-built
  workbench images. Support applies to the official base catalog image only; changes
  introduced by this Containerfile (Kiro CLI install and related layers) are your
  responsibility.
- **Auth at runtime.** Users must log in to Kiro themselves (`kiro-cli login`); credentials
  are not included in the image.
- **Updating the base digest.** After upgrading OpenShift AI, refresh the pin in
  `Containerfile`, rebuild, and re-import / retag:

```bash
oc get is code-server-notebook -n redhat-ods-applications \
  -o jsonpath='{.spec.tags[?(@.name=="3.5")].from.name}{"\n"}'
```

Replace the `@sha256:...` in `Containerfile`, then rebuild and re-register.

## Files

| File | Purpose |
|------|---------|
| `Containerfile` | Image build (public RH base + Kiro CLI) |
| `imagestream.yaml` | Cluster-wide notebook ImageStream (`redhat-ods-applications`) |
| `imagestream-build.yaml` | Optional build-target ImageStream (no dashboard labels) |
| `buildconfig.yaml` | Optional OpenShift binary build |
