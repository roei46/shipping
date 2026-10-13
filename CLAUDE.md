# Shipping — AI shipping coordination (Corona)

## 1. The big picture (original assignment)

כשאלת System Design: מערכת AI לתכנון ותיאום שילוח בינלאומי
חברת Corona במקסיקו מוכרת בירות לברים ולקוחות עסקיים ברחבי העולם. בר בגרמניה מעוניין להזמין משלוח גדול של בירות, אך תהליך תיאום השילוח מתנהל כיום באמצעות שרשרת מיילים ידנית.
כאשר מתקבלת בקשת ההזמנה, נציג במקסיקו צריך להבין מתוך המייל:

* מהי הכמות המבוקשת?
* מהן מידות ומשקל המטען?
* האם מדובר בבקבוקים, פחיות, חביות או משטחים?
* מהו מועד האספקה המבוקש?
* מהן כתובות האיסוף והמסירה?
* האם נדרש משלוח ימי או אווירי?
* האם הלקוח מעדיף מחיר נמוך או אספקה מהירה?
* האם נדרשת בקרת טמפרטורה?
* מי אחראי על המכס, הביטוח וההובלה המקומית?
* מהם תנאי ה־Incoterms?

אם חסרים פרטים, הנציג שולח שאלות חזרה לבר. בגלל הפרשי השעות, כל סבב שאלות ותשובות עלול להוסיף יום שלם לתהליך.
לאחר קבלת הפרטים, הנציג צריך:

1. לבדוק אם שילוח ימי או אווירי מתאים להזמנה.
2. לבחור את אופן איחוד המטען ואת סוג המכולה.
3. לבדוק מועדי הפלגות או טיסות וזמינות קיבולת.
4. לקבל הצעות מחיר מחברות שילוח.
5. להציע ללקוח כמה חלופות.
6. לקבל את אישור הלקוח.
7. להזמין את השילוח הבינלאומי.
8. לתאם משאית מהנמל או משדה התעופה אל הבר.

התהליך כולו נמשך כיום כחמישה עד שבעה ימי עבודה. החברה רוצה לצמצם אותו למספר שעות באמצעות LLM

## 2. Decisions we made

- **One role: the customer (the bar).** There is no sales rep / agent with access to the system. Everything the rep did manually (steps 1–8) is done by the system; the customer approves.
- **iOS app:** one SwiftUI app, customer login only. Screens: Login → Home (My Shipments feed with status) → New Shipment form (14 fields) → Submit result (success / failure) → Options & Approve.
- The status of every shipment is visible in the feed. A push notification is only a shortcut to the Options screen.
- **Server:** FastAPI (Python) + PostgreSQL + Redis (queue) + Celery (worker). The API answers fast; anything slow runs in the background.
- **Two background jobs:**
  - `prepare_options` (on Submit): LLM plan → forwarder quotes in parallel → build options (cheapest / fastest) → save, status `options_ready` → push.
  - `book_shipment` (on Approve): book the chosen option with the forwarder (step 7) → schedule the truck to the bar (step 8).
- **The LLM is used only for steps 1–2:** does sea / air fit, FCL / LCL, which container. Its output is JSON validated by Pydantic. It never produces prices or dates; those come only from the forwarder APIs.
- Forwarders, trucking and push (APNs) are external services called over API.
- Quotes are never cached: prices and capacity change all the time.

## 3. Repo structure

- `ios/` — the iOS app (Xcode, SwiftUI). Rules in `ios/CLAUDE.md`.
- `server/` — the backend (Python, FastAPI). Rules in `server/CLAUDE.md`.
- This file applies to both.

## 4. API contract

The contract between the app and the server. Any change to an endpoint, field or status is made **here first**, then in the server and the app.

### General rules

- All bodies are JSON. Keys are **camelCase**.
- IDs are UUID strings.
- Dates are `"YYYY-MM-DD"`.
- Prices are numbers in USD.
- Every call except login and hello sends the header `Authorization: Bearer <token>`.
- Any 2xx status is success.

### Shipment statuses

| Status              | Set by | When                                   |
|---------------------|--------|----------------------------------------|
| `preparing_options` | API    | On submit                              |
| `options_ready`     | Worker | Options saved (push is sent after)     |
| `approved`          | API    | Customer approved an option            |
| `in_transit`        | Worker | Forwarder confirmed departure          |

### Endpoints

#### 0. Hello (server check)
`GET /hello` — no token

Responses:
- `200` → `{ "message": "hello world" }`

#### 1. Login
`POST /customer/login`

Request:
```json
{ "username": "string", "password": "string" }
```
Responses:
- `200` → `{ "token": "string" }`
- `401` → wrong username or password

#### 2. List shipments (home feed)
`GET /customer/shipments`

Responses:
- `200` →
```json
{ "shipments": [ { "requestId": "uuid", "status": "options_ready" } ] }
```

#### 3. Create shipment (Submit)
`POST /customer/shipments`

Request (all 14 fields required):
```json
{
  "quantity": 1200,
  "weightKg": 9800,
  "dimensions": { "lengthCm": 120, "widthCm": 80, "heightCm": 150 },
  "packageType": "bottles | cans | kegs | pallets",
  "deliveryDate": "2026-11-20",
  "shippingMode": "sea | air",
  "pickupAddress": "string",
  "deliveryAddress": "string",
  "priority": "lowestPrice | fastest",
  "temperatureControl": true,
  "customsBy": "buyer | seller",
  "insuranceBy": "buyer | seller",
  "localTruckingBy": "buyer | seller",
  "incoterms": "EXW | FCA | FOB | CIF | DAP | DDP"
}
```
Validation: `quantity` > 0, `weightKg` > 0, `deliveryDate` must be in the future.

Responses:
- `201` → `{ "requestId": "uuid", "status": "preparing_options" }`
- `422` →
```json
{ "errors": [ { "field": "deliveryDate", "message": "Must be a future date" } ] }
```
`field` is the camelCase key from the request.

#### 4. Shipment details + options
`GET /customer/shipments/{id}`

Responses:
- `200` →
```json
{
  "requestId": "uuid",
  "status": "options_ready",
  "options": [
    {
      "optionId": "uuid",
      "mode": "sea | air",
      "price": 4800,
      "estimatedArrival": "2026-11-18",
      "containerType": "20ft | 40ft | 40ft_reefer | uld"
    }
  ]
}
```
`options` is empty while the status is `preparing_options`.
- `404` → not found, or not this customer's shipment

#### 5. Approve an option
`POST /customer/shipments/{id}/approve`

Request:
```json
{ "optionId": "uuid" }
```
Responses:
- `200` → `{ "requestId": "uuid", "status": "approved" }`
- `404` → not found, or not this customer's shipment
- `409` → shipment is not `options_ready` (e.g. already approved)

#### 6. Register device for push
`POST /customer/devices`

Request:
```json
{ "deviceToken": "string" }
```
Responses:
- `201` → `{ "id": "uuid" }`

### Push notification payload (server → app)

Sent when a shipment becomes `options_ready`. Tapping it opens the Options screen.
```json
{
  "aps": { "alert": { "title": "Your options are ready", "body": "Tap to choose a shipping option" } },
  "shipmentId": "uuid"
}
```
