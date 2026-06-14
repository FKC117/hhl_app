# HHL Flutter API Contract

This document is the current mobile-facing backend contract for the Flutter app.

## Base URL

Development examples:

- Android emulator: `http://10.0.2.2:8000`
- Physical phone on same Wi-Fi: `http://YOUR_PC_LAN_IP:8000`
- iOS simulator on macOS would normally use `http://127.0.0.1:8000`, but your current setup is Windows.

Base API prefix:

```text
/api/v1/
```

## Auth

- `POST /api/v1/auth/login/`
- `POST /api/v1/auth/refresh/`
- `POST /api/v1/auth/logout/`
- `GET /api/v1/auth/me/`
- `POST /api/v1/auth/change-password/`
- `POST /api/v1/auth/forgot-password/`

Login request:

```json
{
  "email": "patient@example.com",
  "password": "StrongPass123!"
}
```

Login response:

```json
{
  "refresh": "jwt-refresh",
  "access": "jwt-access",
  "user": {
    "id": 1,
    "phone": "+8801700000000",
    "email": "patient@example.com",
    "first_name": "Test",
    "last_name": "Patient",
    "role": "PATIENT",
    "is_phone_verified": false,
    "date_joined": "2026-06-14T10:00:00Z"
  }
}
```

## Pagination

All list endpoints now use paginated responses:

```json
{
  "count": 1,
  "next": null,
  "previous": null,
  "results": []
}
```

Supported query params:

- `page`
- `page_size`

## Doctors

- `GET /api/v1/doctors/departments/`
- `GET /api/v1/doctors/`
- `GET /api/v1/doctors/{id}/`
- `GET /api/v1/appointments/slots/?schedule={id}&date=YYYY-MM-DD`

Doctor list filters:

- `department`
- `search`
- `mode`

## Appointments

- `GET /api/v1/appointments/`
- `POST /api/v1/appointments/draft/`
- `GET /api/v1/appointments/{id}/`
- `POST /api/v1/appointments/{id}/confirm/`
- `POST /api/v1/appointments/{id}/cancel/`

Appointment list filters:

- `status`
- `date_from`
- `date_to`

Draft request:

```json
{
  "schedule": 1,
  "appointment_date": "2026-06-20",
  "appointment_time": "09:00:00",
  "patient_note": "Routine consultation"
}
```

Confirm request:

```json
{
  "payment_id": 12
}
```

## Diagnostics

- `GET /api/v1/diagnostics/labs/`
- `GET /api/v1/diagnostics/labs/{id}/`
- `GET /api/v1/diagnostics/labs/{id}/departments/`
- `GET /api/v1/diagnostics/labs/{id}/tests/`
- `GET /api/v1/diagnostics/orders/`
- `POST /api/v1/diagnostics/orders/draft/`
- `GET /api/v1/diagnostics/orders/{id}/`
- `POST /api/v1/diagnostics/orders/{id}/confirm/`
- `POST /api/v1/diagnostics/orders/{id}/cancel/`

Diagnostic list filters:

- `status`
- `lab`

Lab test filters:

- `department`
- `search`

Draft request:

```json
{
  "lab": 1,
  "tests": [2, 3],
  "patient_note": "Morning collection preferred"
}
```

## Reports

- `GET /api/v1/reports/`
- `GET /api/v1/reports/{id}/`
- `GET /api/v1/reports/{id}/download/`

Report list filters:

- `lab`

## Prescriptions

- `GET /api/v1/prescriptions/`
- `GET /api/v1/prescriptions/{id}/`
- `GET /api/v1/prescriptions/{id}/download/`

Prescription list filters:

- `appointment`

## Invoices

- `GET /api/v1/invoices/`
- `GET /api/v1/invoices/{id}/`
- `GET /api/v1/invoices/{id}/download/`

Invoice list filters:

- `invoice_type`

## Payments

- `POST /api/v1/payments/initiate/`
- `POST /api/v1/payments/{id}/complete/`
- `GET /api/v1/payments/{id}/`

Initiate request:

```json
{
  "source_type": "APPOINTMENT",
  "source_id": 4,
  "gateway": "manual"
}
```

Local prototype payment completion:

- `POST /api/v1/payments/{id}/complete/`
- available for patient-owned `manual` payments in initiated state
- intended for local/dev flow so Flutter can move from payment screen to confirmed booking

## Ambulance

- `POST /api/v1/ambulance/request/`
- `GET /api/v1/ambulance/requests/`
- `GET /api/v1/emergency-contact/`

Ambulance request payload:

```json
{
  "pickup_address": "House 12, Road 4, Dhaka",
  "destination_address": "HHL Hospital",
  "contact_number": "+8801711111111",
  "notes": "Chest pain and breathing difficulty."
}
```

Ambulance request rules from backend:

- `pickup_address` is required
- `contact_number` is required
- `destination_address` is optional
- `notes` is optional

Ambulance request response shape:

```json
{
  "id": 15,
  "patient": 3,
  "pickup_address": "House 12, Road 4, Dhaka",
  "destination_address": "HHL Hospital",
  "contact_number": "+8801711111111",
  "status": "REQUESTED",
  "status_display": "Requested",
  "notes": "Chest pain and breathing difficulty.",
  "created_at": "2026-06-14T12:30:00Z",
  "updated_at": "2026-06-14T12:30:00Z"
}
```

Ambulance list filters:

- `status`

Valid ambulance status values:

- `REQUESTED`
- `ACCEPTED`
- `ON_THE_WAY`
- `COMPLETED`
- `CANCELLED`

Emergency contact response item:

```json
{
  "id": 1,
  "title": "National Emergency",
  "phone_number": "999"
}
```

## Call Center

- `GET /api/v1/callcenter/me/`
- `PATCH /api/v1/callcenter/me/`
- `GET /api/v1/callcenter/ambulance/requests/`
- `GET /api/v1/callcenter/ambulance/requests/{id}/`
- `PATCH /api/v1/callcenter/ambulance/requests/{id}/status/`

Call center ambulance filters:

- `status`

## File Downloads

Reports, prescriptions, and invoices are protected endpoints. Flutter should:

1. send the bearer token
2. download the bytes
3. save/open locally

Do not assume public media URLs.

## Flutter Workflow

You do not need the Django code inside the Flutter repo.

Recommended workflow:

1. Keep this Django backend running locally.
2. Start the Flutter app in a separate project folder.
3. Point Flutter `baseUrl` to this backend.
4. Use the real APIs from the running backend during UI work.

Practical examples:

- backend terminal:
  `.\venv\Scripts\python.exe .\hhl\manage.py runserver 0.0.0.0:8000`
- Flutter Android emulator base URL:
  `http://10.0.2.2:8000/api/v1/`
- Flutter physical device base URL:
  `http://192.168.x.x:8000/api/v1/`

If you close this Django project in Codex, the Flutter app can still talk to the API as long as the Django server is running from your machine.
