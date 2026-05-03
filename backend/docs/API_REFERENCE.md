# Crop Doctor Backend — REST API Reference

Use this guide with Postman or any HTTP client.

## Base URL

Replace with your deployment host:

```
{{base_url}} = http://127.0.0.1:8000   or   https://your-domain.com
```

All listed paths are prefixed from the project root (no `/api` on Django admin).

## Authentication

| Style | Usage |
|--------|--------|
| **Token (DRF)** | Header: `Authorization: Token <your_token_key>` |

- Obtain token from **`POST /api/users/register/`** or **`POST /api/users/login/`**.
- **`POST /api/users/logout/`** removes the token (send the same header).

Premium-gated endpoints use `IsPremiumAccess`: **`paid`** with an **active, non-expired** subscription (see `UserSubscription.active_now_for_user`), or **`expert`** / **`superadmin`** bypass.

Guest scan (**`POST /api/scan/`**) allows **no** token if the client sends **`guest_id`** (or **`X-Guest-Id`** header): **max 3 scans per calendar week** per `guest_id`.

---

## Django Admin (browser / session cookie)

Not token-based — use staff login.

| Method | Path | Auth |
|--------|------|------|
| BROWSER | `/admin/` | Session (staff account) |

---

## 1. Users (`users`)

Base path: **`/api/users/`**

### 1.1 Register

| Item | Value |
|------|--------|
| **POST** | `/api/users/register/` |
| Auth | None |

**JSON body:**

```json
{
  "username": "jdoe",
  "email": "jdoe@example.com",
  "phone": "",
  "password": "SecurePass123",
  "confirm_password": "SecurePass123"
}
```

**Example success (201):**

```json
{
  "message": "Registration successful",
  "token": "YOUR_TOKEN_HERE",
  "role": "guest"
}
```

---

### 1.2 Login

| Item | Value |
|------|--------|
| **POST** | `/api/users/login/` |
| Auth | None |

**JSON body:**

```json
{
  "username": "jdoe",
  "password": "SecurePass123"
}
```

**Example success (200):**

```json
{
  "token": "YOUR_TOKEN_HERE",
  "role": "guest"
}
```

---

### 1.3 Profile — get / patch / delete

| Item | Value |
|------|--------|
| **GET** | `/api/users/profile/` |
| **PATCH** | `/api/users/profile/` |
| **DELETE** | `/api/users/profile/` |
| Auth | `Token …` |

`role` and `is_verified` are read-only.

**PATCH JSON (partial examples):**

```json
{
  "email": "new@example.com",
  "phone": "01700000000"
}
```

Multipart (optional **`profile_image`** file):

```
PATCH /api/users/profile/
Content-Type: multipart/form-data

phone=01700000000
profile_image=<file>
```

---

### 1.4 Logout

| Item | Value |
|------|--------|
| **POST** | `/api/users/logout/` |
| Auth | `Token …` |

Body: empty `{}` optional.

---

### 1.5 Admin — Users (superadmin only)

Router base: **`/api/users/admin/users/`**

Requires **`role`: `superadmin`**.

| Method | Path |
|--------|------|
| **GET** | `/api/users/admin/users/` — list |
| **POST** | `/api/users/admin/users/` — create |
| **GET** | `/api/users/admin/users/{id}/` — detail |
| **PUT** / **PATCH** | `/api/users/admin/users/{id}/` |
| **DELETE** | `/api/users/admin/users/{id}/` |
| **PATCH** | `/api/users/admin/users/{id}/verify/` — verification flag |

**Create JSON (minimal):**

```json
{
  "username": "expert1",
  "email": "expert@example.com",
  "phone": "",
  "role": "expert",
  "is_verified": true,
  "is_active": true,
  "is_staff": false,
  "password": "TempPass123"
}
```

Role is only set/changed when the acting user is **`superadmin`** (`AdminUserSerializer`).

**PATCH verify:**

```json
{
  "is_verified": true
}
```

Create/update may include **`profile_image`** as multipart fields alongside JSON-like keys.

---

### 1.6 Expert — Users (`expert` or `superadmin`)

Base: **`/api/users/expert/users/`**

| Method | Path |
|--------|------|
| **GET** | `/api/users/expert/users/` |
| **GET** | `/api/users/expert/users/{id}/` |
| **PATCH** | `/api/users/expert/users/{id}/verify/` |

List includes users with roles **`guest`**, **`paid`**, or **`expert`**.

Expert verify (**only target role `paid`**):

```json
{
  "is_verified": true
}
```

---

## 2. Scan (`scan`)

### 2.1 Disease scan

| Item | Value |
|------|--------|
| **POST** | `/api/scan/` |
| Content-Type | `multipart/form-data` |

### Guest (no token)

Send:

- **`image`** (file): leaf photo  
- **`crop`** (text): crop name (e.g. `tomato`, `Tomato`; backend normalizes)  
- **`guest_id`** **or** header **`X-Guest-Id`**: stable UUID from the app  

Limit: **3 successful guest scans per calendar week** per `guest_id`.

### Authenticated (`paid` + active subscription or `expert` / `superadmin`)

Send:

- **`Authorization`: `Token …`  
- **`image`**, **`crop`**  
- Do **not** rely on `guest_id`.

**Example multipart fields (guest):**

| Key | Value |
|-----|--------|
| image | `(binary)` |
| crop | `"tomato"` |
| guest_id | `"xxxxxxxx-xxxx-4xxx-xxxx-xxxxxxxxxxxx"` |

Responses vary (`200`, `400`, `422`, `403`, `502`, etc., depending on permission, guest limit, or ML service). Typical success includes **`prediction`** and optional **`solution`**.

---

## 3. Subscriptions (`subscriptions`)

Base path segments below are appended to **`/api/`** exactly as configured (see `subscriptions/urls.py`).

### 3.1 Admin — Subscription plans (`superadmin`)

| Method | Path |
|--------|------|
| **GET** | `/api/admin/get-plans/` |
| **POST** | `/api/admin/create-plan/` |
| **PUT** | `/api/admin/update-plan/{pk}/` |
| **DELETE** | `/api/admin/delete-plan/{pk}/` |

**POST / PUT JSON (plan fields — `SubscriptionPlan`):**

```json
{
  "name": "monthly",
  "price": "299.00",
  "duration_days": 30
}
```

Valid **`name`** values: **`monthly`**, **`yearly`** (`PLAN_CHOICES`).

---

### 3.2 Admin — User subscriptions (`superadmin`)

| Method | Path |
|--------|------|
| **GET** | `/api/admin/get-subscriptions/` — intended list (see codebase note*) |
| **GET** | `/api/admin/get-subscription/{pk}/` |
| **PUT** | `/api/admin/update-subscription/{pk}/` |
| **DELETE** | `/api/admin/delete-subscription/{pk}/` |

\*The view class declares two **`get`** methods in Python — the latter overrides the former; validate list vs detail behaviour in deployment.

**PUT body (subscription status workflow):**

```json
{
  "status": "active"
}
```

Allowed **`status`** string values (`UserSubscription.STATUS_CHOICES`):  
`pending`, `active`, `expired`, `cancelled`.

- **`active`** triggers **`subscription.activate()`** (sets window, **`guest → paid`** if applicable).  
- **`cancelled`** triggers **`subscription.cancel()`** (may downgrade **`paid → guest`** if no other active subscription).  
Other values update **`status`** / **`is_active`** without calling **`activate()`** / **`cancel()`**.

---

### 3.3 Create payment session (authenticated user)

| Item | Value |
|------|--------|
| **POST** | `/api/subscriptions/create-subscription-payment/` |
| Auth | `Token …` |

**JSON body:**

```json
{
  "plan_id": 1
}
```

**Example success:**

```json
{
  "payment_url": "https://…",
  "transaction_id": "uuid-from-server"
}
```

Requires SSLCOMMERZ env vars in `settings`; gateway returns `payment_url` for redirect.

---

### 3.4 Payment callbacks (usually called by gateway / redirects)

No token by default (**`permission_classes = []`** on these).

| Method | Path | Typical body |
|--------|------|----------------|
| **POST** | `/api/subscriptions/payment-success/` | `{"tran_id": "<transaction_id>"}` |
| **POST** | `/api/subscriptions/payment-fail/` | `{"tran_id": "<transaction_id>"}` |
| **POST** | `/api/subscriptions/payment-cancel/` | `{"tran_id": "<transaction_id>"}` |
| **POST** | `/api/subscriptions/payment-ipn/` | Gateway payload (often form); code reads `tran_id`, `status` |

**IPN example (conceptual JSON):**

```json
{
  "tran_id": "YOUR_UUID_TRANSACTION",
  "status": "VALID"
}
```

Production gateways often POST **form-urlencoded** fields with the same names — Postman should use **x-www-form-urlencoded** or raw form if needed.

SSLCommerz may also send **`status`: `FAILED`** in IPN logic.

---

## 4. Forums (`forums`)

All routes require **`Authorization: Token …`** and **`IsPremiumAccess`** (paid + active sub, or expert/superadmin).

Base: **`/api/`** prefix as defined in URLs below.

---

### 4.1 Questions

| Method | Path |
|--------|------|
| **GET** | `/api/questions/get-all-questions/` — current user’s questions |
| **GET** | `/api/question/{pk}/` — one question |
| **POST** | `/api/question/create-question/` |
| **PUT** | `/api/question/{pk}/update-question/` — partial handled as partial serializer |
| **DELETE** | `/api/question/{pk}/delete-question/` |

**POST multipart / JSON:**

```json
{
  "title": "Yellow spots on leaves",
  "description": "Noticed irregular yellow patches…",
  "crop": "tomato",
  "status": "open",
  "image": null
}
```

For uploads use **multipart** with optional **`image`** file.  
**`status`**: `"open"` | `"answered"` | `"closed"`.

**PUT / PATCH-like update (multipart or JSON partial):**

```json
{
  "title": "Updated title",
  "status": "closed"
}
```

---

### 4.2 Answers

| Method | Path |
|--------|------|
| **GET** | `/api/answers/get-all-answers/` — current user’s answers |
| **GET** | `/api/answer/{pk}/` |
| **POST** | `/api/answer/create-answer/` |
| **PUT** | `/api/answer/{pk}/update-answer/` |
| **DELETE** | `/api/answer/{pk}/delete-answer/` |

**POST JSON:**

```json
{
  "question": 14,
  "text": "This looks like septoria leaf spot. Try copper fungicide..."
}
```

**PUT JSON (partial):**

```json
{
  "text": "Edited answer."
}
```

**`question`** reassignment allowed only if acting user role is **`superadmin`**.

Experts get **`is_expert`: true** automatically when saving (**`Answer.save`** logic).

---

### 4.3 Answer like toggle

| Item | Value |
|------|--------|
| **POST** | `/api/answer/{pk}/like/` |

No body needed (optional `{}`).  
Cannot like your own answer (returns error).

Responses include `"liked"` / `"unliked"` messages.

---

## 5. Media & static (`DEBUG`)

With **`DEBUG=True`**, `settings` expose **`/media/`** and **`/static/`**.

---

## 6. Postman workflow (quick)

1. **Register** or **login** → copy **`token`**.
2. In Postman Collection / environment:  
   **`Authorization`** → **`Token {{token}}`** on `Header` **`Authorization`** or type **Bearer** not used — this project uses raw **`Token <key>`**.
3. For **scan**: type **form-data**, add file key **`image`**, text **`crop`**, and **`guest_id`** for guest mode.
4. For **profile image** / **question image**: **form-data** with file fields.

---

## 7. Importable collection

Import **`docs/CropDoctor.postman_collection.json`** into Postman; set collection variables **`base_url`** and **`token`**.
