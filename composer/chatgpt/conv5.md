Ah 👍 good catch — you’re right.

`gcloud artifacts packages upload` **does not exist**.
For **PyPI repositories**, the correct way is to treat **Artifact Registry** just like a private PyPI index and push packages with `twine` (or `pip upload`).

---

## 🔹 Correct Steps to Upload Python Packages to Artifact Registry PyPI

1. **Authenticate `twine` with Artifact Registry**

```bash
gcloud auth application-default login
gcloud auth print-access-token | \
  twine upload --repository-url=https://asia-south1-python.pkg.dev/prj-gdg-ai-meetup-20250717/composer-pypi/ \
  -u oauth2accesstoken -p $(gcloud auth print-access-token) dist/*
```

2. **Build the wheel for the package**

```bash
pip download requests==2.31.0 -d dist
```

This gives you a `.whl` or `.tar.gz`.

3. **Upload to Artifact Registry PyPI repo**

```bash
twine upload --repository-url=https://asia-south1-python.pkg.dev/prj-gdg-ai-meetup-20250717/composer-pypi/ \
  -u oauth2accesstoken -p $(gcloud auth print-access-token) dist/*
```

---

✅ After upload, Composer will be able to install `requests==2.31.0` because your `env_variables.PIP_INDEX_URL` points to this repo.

⚠️ Important: Artifact Registry **does not proxy PyPI**.
You must upload **all required dependencies** (`urllib3`, `idna`, `charset-normalizer`, `certifi` for `requests`) — otherwise Airflow will fail at install time.

---

👉 Do you want me to give you a **helper script** that automatically resolves all dependencies from public PyPI, downloads them, and re-uploads into Artifact Registry (so you don’t have to chase missing wheels manually)?



Got it 👍 — by default `twine` isn’t installed with Python, that’s why you’re seeing `command not found`.

You’ll need to install it once on the machine where you plan to upload packages:

### 1. Install `twine`

```bash
pip install twine
```

(or if you’re using Python 3 explicitly)

```bash
pip3 install twine
```

Verify:

```bash
twine --version
```

---

### 2. Download the package + dependencies

Since Artifact Registry PyPI **does not proxy** PyPI, you need to upload *all* dependencies:

```bash
mkdir dist
pip download requests==2.31.0 -d dist
```

This will give you `requests` + all its dependencies (`urllib3`, `certifi`, `idna`, `charset-normalizer`).

---

### 3. Upload to Artifact Registry

Use `twine` with GCP access token:

```bash
twine upload \
  --repository-url=https://asia-south1-python.pkg.dev/prj-gdg-ai-meetup-20250717/composer-pypi/ \
  -u oauth2accesstoken -p $(gcloud auth print-access-token) \
  dist/*
```

---

✅ Now your Composer environment will be able to pull `requests==2.31.0` and its deps directly from Artifact Registry.

---

Do you want me to write you a **single script** that automates steps 2 & 3 (download all deps + upload to Artifact Registry) so you can reuse it for any package?
