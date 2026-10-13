# Troubleshooting

Problems that have actually bitten this project, what they looked like, and
what fixed them. Each entry starts with the symptom, because that is what you
have when something breaks.

The two repos:

| | |
|---|---|
| App (Flutter) | `~/pakka-homes` → `physioxapp1-sys/pakka-homes` |
| Backend (Django) | `~/dhaubanjar-nirman-sewa` → `physioxapp1-sys/dhaubanjar-nirman-sewa` |
| Live API | `https://www.dhaubanjarnirmansewa.com.np/api/v1` |
| Server path | `/home2/madhyapu/dhaubanjar-nirman-sewa` |
| Server venv | `/home2/madhyapu/virtualenv/dhaubanjar-nirman-sewa/3.11/bin/python` |

---

## "Connection reset by peer", or a screen that silently shows nothing

**Cause: the host's bot filter is answering instead of Django.**

LiteSpeed serves a *Bot Verification* reCAPTCHA page — HTML, with a `200` —
to clients it does not recognise. Every request from the app gets it,
including `GET /health/`. Reads appear to work only because the catalog falls
back to bundled images when a fetch fails.

Check which clients get through:

```bash
B=https://www.dhaubanjarnirmansewa.com.np/api/v1
for ua in "curl/8.0" "Dart/3.5 (dart:io)" "PakkaHomes/1.0 (Android)"; do
  printf '%-28s ' "$ua"
  curl -s -A "$ua" "$B/health/" | head -c 60; echo
done
```

JSON means that client is allowed. `<!DOCTYPE html>` means it is being
challenged. When last tested only `curl/*` passed — a real Chrome Android
agent was challenged too, so this is an allowlist, not a browser check.

**The fix is server-side, and it worked.** The reCAPTCHA / anti-bot filter
was disabled for this domain (October 2026) and sign-up and sign-in started
working immediately, with no app change. The alternative is to allowlist the
app's User-Agent (`PakkaHomes/1.0 (Android)`, set in
`lib/data/api_client.dart`). It is usually a WHM-level setting, so a
cPanel-only account cannot change it alone.

If this ever comes back — a host re-enables the filter, or it is turned on for
a new subdomain — the symptom is the same *"server returned a web page"*
message, and the `curl` loop above is the quickest way to confirm it before
touching any code. Nothing in the app needs changing.

Do **not** make the app pretend to be `curl` to slip past. It would work today
and break the moment the rule changes, and it defeats a protection that is
there on purpose.

The app now reports this as *"the server returned a web page instead of
data"*. Before, `jsonDecode` hit HTML and threw an uncaught `FormatException`
far from the cause.

---

## Sign-up refused, then sign-in fails too

**Cause: the form promised a password rule the server does not accept.**

The server runs Django's validators: **8+ characters, not a common password,
not all digits**. The form used to ask for 6. People were turned away for a
rule nothing had stated, and sign-in then failed because the account they
believed they had created never existed.

```bash
curl -s -X POST "$B/auth/register/" -H "Content-Type: application/json" \
  -A "curl/8.0" -d '{"phone":"9800000000","password":"abc123"}'
# {"password":["This password is too short...","This password is too common."]}
```

Fixed in `lib/screens/auth_screen.dart` (asks for 8, states the rule under the
field) and `accounts/serializers.py` (`min_length=8`, matching its own
validator).

> **When testing register against the live API, use a password that will be
> rejected.** A valid one creates a real account in production. That happened
> once; it had to be deleted with
> `DELETE /auth/me/` + `{"password": "..."}` and the token confirmed dead.
> Better: test against a throwaway SQLite database (see below).

---

## `Unknown command: 'import_catalog'` / `No module named 'dotenv'`

**Cause: the wrong project or the wrong virtualenv.**

The shell often auto-activates `sajhya.com`, a different Django site on the
same account. Check the prompt — `((sajhya.com:3.11))` means the wrong
environment, and every path in the traceback will say so too.

Call the right interpreter directly and the question disappears:

```bash
cd ~/dhaubanjar-nirman-sewa
~/virtualenv/dhaubanjar-nirman-sewa/3.11/bin/python manage.py import_catalog
```

`deploy.sh` guesses a different venv path (`~/virtualenv/repositories/...`).
`ls ~/virtualenv/` settles which exists.

---

## `Data too long for column 'name'` during import

**Cause: SQLite does not enforce `VARCHAR` length and MySQL does.**

The shop sheet carries a helper cell per row holding that row's own
subcategories comma-joined in parentheses. Imported as subcategories, six of
them exceeded `name`'s 160 characters and MySQL aborted the run.

Fixed in `import_catalog` — it skips parenthesised joined cells and anything
longer than the column, naming what it dropped.

**The wider lesson: a local SQLite pass does not prove a MySQL run.** For
anything schema-sensitive, assert the data fits before deploying:

```python
lim = Subcategory._meta.get_field('name').max_length
assert not [s for s in Subcategory.objects.all() if len(s.name) > lim]
```

---

## A tile shows a placeholder, or the wrong rate under a picture

**Cause: the picture is not on the server, or the row it belongs to changed.**

Tiles come from `/subcategories/` now — one row is one tile, carrying its own
name, rate and image URL. A grey placeholder means that row has no image:
upload one on the subcategory in Django admin, or run `import_catalog_images`
if it has never been run on this server.

It used to work the other way: the app shipped numbered images and paired tile
N with the Nth row from the API. That drifted the moment anyone touched the
catalog, and it had — grocery was showing Rice's rate under Vegetables &
Fruits. If you see a mismatch like that again, it is **not** this bug; it means
the image attached to that row is genuinely the wrong file. Re-run with
`--replace`.

An empty category means the API returned no subcategories for that slug — check
the category exists and its rows are active in admin.

---

## Deploying

```bash
cd ~/dhaubanjar-nirman-sewa
git pull
~/virtualenv/dhaubanjar-nirman-sewa/3.11/bin/python manage.py migrate
~/virtualenv/dhaubanjar-nirman-sewa/3.11/bin/python manage.py import_catalog
~/virtualenv/dhaubanjar-nirman-sewa/3.11/bin/python manage.py import_catalog_images
~/virtualenv/dhaubanjar-nirman-sewa/3.11/bin/python manage.py seed_products
~/virtualenv/dhaubanjar-nirman-sewa/3.11/bin/python manage.py import_product_images
~/virtualenv/dhaubanjar-nirman-sewa/3.11/bin/python manage.py seed_providers
touch tmp/restart.txt      # Passenger reloads on mtime change
```

All of these are safe to re-run: they update what changed and leave the rest
alone. The two image commands skip anything that already has a picture unless
passed `--replace`.

`import_catalog_images` is not optional any more. The app no longer ships tile
images — it draws whatever the API serves — so until this has run, every
subcategory tile shows a placeholder.

`import_catalog` needs no path: it defaults to `catalog/data/catalog.xlsx`,
vendored in the backend repo. That copy is **not** the app's spreadsheet — when
`pakka-homes/xlsx/data - Copy.xlsx` changes, copy it over and commit, or the
import will quietly load the old catalog.

Expect **39 categories / 348 items**. If `categories/?vertical=service` returns
`count: 0`, the import never ran and every screen is on bundled images with no
prices.

---

## Testing the backend without touching production

```bash
cd ~/dhaubanjar-nirman-sewa
export DJANGO_SETTINGS_MODULE=config.settings DEBUG=True SECRET_KEY=dev \
       DB_ENGINE=sqlite DB_NAME=_tmp.sqlite3 ALLOWED_HOSTS=testserver
python manage.py migrate && python manage.py import_catalog
python manage.py seed_providers
# ... django.test.Client requests here ...
rm -f _tmp.sqlite3
```

`config/settings.py` falls back to SQLite when `DB_ENGINE=sqlite`, so this
never reaches the real database. Remember it is more permissive than MySQL.

---

## Things that look broken but are not

| Looks like | Actually |
|---|---|
| Every service priced "On request" | `Subcategory.rate` is empty across the catalog. Rates are entered in the Django admin. |
| Grocery has no rates | It is in the sheet now, but like everything else has no price set. |
| `/api/v1/providers/` returns 401 | Deliberate — the roster is staff-only, so it is not scraped or used to go direct. |
| Bookings tab empty after booking as a guest | Signing up with the same number claims those bookings. |
| Rent / Maid do nothing | Not built — the tiles are greyed and badged "Coming soon". |
| Construction, Mason, Painting, Carpenter, Interior unreachable | The four-tile home only surfaces Grocery plus five trades under Maintenance. Their data and images are intact; add a slug to `_maintenanceSlugs`. |
| Password reset code never arrives | No SMS gateway is wired in. The code is written to the Django log; the rest of the flow works against it. |

---

## Checks worth running before shipping

There is no Flutter SDK on the development machine, so the app is verified
statically. These have each caught something real:

```bash
# brackets balance in every Dart file
for f in lib/**/*.dart; do python3 -c "
s=open('$f',encoding='utf-8').read(); c={x:s.count(x) for x in '()[]{}'}
print(('OK ' if c['(']==c[')'] and c['[']==c[']'] and c['{']==c['}'] else 'BAD'), '$f')"; done

# every asset referenced in code exists on disk
# every AppColors token used is still defined
# every category slug the UI looks up exists in local_catalog
```

The last one matters: `_category(slug)` uses `firstWhere`, which **throws at
runtime** if a slug is missing — it will not fail at compile time.
