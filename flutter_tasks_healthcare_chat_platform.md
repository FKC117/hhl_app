# Healthcare Chat-First Platform — Flutter App Tasks

## 1. Product Concept

Build a Flutter mobile app with a ChatGPT-like healthcare interface.

The app will allow users to:

- Chat with a healthcare assistant
- Use manual feature buttons/cards
- Book doctor appointments
- Book diagnostic tests
- View reports
- View prescriptions
- View invoices
- Request ambulance
- Call emergency center

The interface should be chat-first, but every major feature must also be manually accessible.

---

## 2. Recommended Flutter Stack

```text
Flutter SDK
Dart
Material 3
GoRouter for navigation
Riverpod for state management
Dio for API calls
Flutter Secure Storage for tokens
Freezed/json_serializable for models later
Cached Network Image for images
File opener/downloader for reports and prescriptions
```

---

## 3. App Architecture

Use feature-first architecture.

```text
lib/
│
├── main.dart
│
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme.dart
│
├── core/
│   ├── constants/
│   ├── config/
│   ├── api/
│   ├── auth/
│   ├── storage/
│   ├── errors/
│   └── utils/
│
├── shared/
│   ├── widgets/
│   ├── models/
│   └── layouts/
│
└── features/
    ├── splash/
    ├── auth/
    ├── dashboard/
    ├── chat/
    ├── doctors/
    ├── appointments/
    ├── diagnostics/
    ├── reports/
    ├── prescriptions/
    ├── invoices/
    ├── ambulance/
    └── profile/
```

---

## 4. Core App Layout

The main logged-in screen should look like:

```text
------------------------------------------------
| Menu / Service Buttons | Chat + Dynamic Cards |
------------------------------------------------
```

On mobile, the left-side menu should become:

```text
Bottom navigation
or
Drawer
or
Horizontal service chips above chat
```

Recommended mobile layout:

```text
Top App Bar
Service shortcut chips
Chat area
Dynamic action cards
Message input box
```

---

## 5. Main User Experience

### Chat-Based Flow

```text
User types health issue or service request
        ↓
Assistant replies with guidance
        ↓
Assistant presents service cards
        ↓
User selects doctor/lab/test/slot
        ↓
Assistant creates draft booking
        ↓
User confirms
        ↓
System books appointment/test
```

### Manual Flow

```text
User taps Doctors / Labs / Reports / etc.
        ↓
Feature screen opens
        ↓
User completes task manually
```

---

## 6. Main Screens

### Public Screens

```text
Splash Screen
Login Screen
Forgot Password Screen
```

### Logged-In Screens

```text
Home Chat Screen
Patient Dashboard
Doctor List
Doctor Detail
Appointment Booking
Diagnostic Lab List
Test List
Diagnostic Cart
Reports
Prescriptions
Invoices
Ambulance Request
Profile
```

---

## 7. Authentication Tasks

### Screens

- Login screen
- Forgot password screen
- Token loading screen
- Logout action

### API Integration

```text
POST /api/auth/login/
POST /api/auth/refresh/
POST /api/auth/logout/
GET  /api/auth/me/
```

### Storage

Use secure storage for:

```text
access_token
refresh_token
user_role
user_id
```

### Tasks

- [ ] Create auth models
- [ ] Create auth repository
- [ ] Create auth controller/provider
- [ ] Save JWT tokens securely
- [ ] Auto-refresh token
- [ ] Redirect logged-in user to chat home
- [ ] Redirect logged-out user to login

---

## 8. Chat Feature Tasks

### Chat UI Requirements

- User messages on right
- Assistant messages on left
- Typing indicator
- Chat history
- Dynamic cards inside chat
- Confirmation buttons
- Suggested quick replies
- Error state
- Retry message option

### APIs

```text
POST /api/chat/sessions/
GET  /api/chat/sessions/
GET  /api/chat/sessions/{id}/messages/
POST /api/chat/sessions/{id}/messages/
POST /api/chat/jobs/{id}/confirm/
POST /api/chat/jobs/{id}/cancel/
```

### Chat Message Types

```text
text
doctor_cards
lab_cards
test_cards
appointment_slots
diagnostic_cart
report_summary
prescription_explanation
invoice_card
confirmation_card
emergency_warning
```

### Tasks

- [ ] Create chat session model
- [ ] Create chat message model
- [ ] Create chat repository
- [ ] Create chat provider
- [ ] Build chat bubble widget
- [ ] Build dynamic card renderer
- [ ] Build message input box
- [ ] Build send-message flow
- [ ] Build loading/typing state
- [ ] Build confirm/cancel AI job flow

---

## 9. Service Shortcut UI

At the top or side of the chat screen, show service buttons:

```text
Doctors
Diagnostic Tests
Reports
Prescriptions
Invoices
Ambulance
Emergency Call
```

### Tasks

- [ ] Create service shortcut chips/cards
- [ ] Open doctor feature manually
- [ ] Open diagnostic feature manually
- [ ] Open reports manually
- [ ] Open prescriptions manually
- [ ] Open invoices manually
- [ ] Open ambulance request manually
- [ ] Direct emergency call button

---

## 10. Doctor Feature Tasks

### Screens

```text
Doctor List Screen
Doctor Detail Screen
Doctor Slot Screen
Appointment Confirmation Screen
Appointment History Screen
```

### APIs

```text
GET  /api/doctors/
GET  /api/doctors/{id}/
GET  /api/doctors/{id}/slots/
POST /api/appointments/draft/
POST /api/appointments/{id}/confirm/
GET  /api/appointments/
POST /api/appointments/{id}/cancel/
```

### UI Components

- Doctor card
- Department filter
- Search bar
- Online/offline badge
- Fee display
- Slot selector
- Confirmation card
- Appointment status badge

### Tasks

- [ ] Create doctor model
- [ ] Create doctor repository
- [ ] Build doctor list screen
- [ ] Build department filter
- [ ] Build doctor details screen
- [ ] Build slot selector
- [ ] Build appointment draft creation
- [ ] Build appointment confirmation
- [ ] Build appointment history

---

## 11. Diagnostic Feature Tasks

### Screens

```text
Lab List Screen
Lab Detail Screen
Test List Screen
Diagnostic Cart Screen
Diagnostic Order Confirmation Screen
Diagnostic Order History Screen
```

### APIs

```text
GET  /api/labs/
GET  /api/labs/{id}/
GET  /api/labs/{id}/tests/
POST /api/diagnostics/orders/draft/
POST /api/diagnostics/orders/{id}/confirm/
GET  /api/diagnostics/orders/
```

### UI Components

- Lab card
- Test department filter
- Test card
- Add/remove test button
- Diagnostic cart
- Price summary
- Order status badge

### Tasks

- [ ] Create lab model
- [ ] Create diagnostic test model
- [ ] Create diagnostic cart model
- [ ] Create diagnostics repository
- [ ] Build lab list screen
- [ ] Build test list screen
- [ ] Build add/remove test flow
- [ ] Build diagnostic cart
- [ ] Build order draft creation
- [ ] Build order confirmation
- [ ] Build order history

---

## 12. Reports Feature Tasks

### Screens

```text
Reports List Screen
Report Detail Screen
Report Download Screen
Report AI Interpretation Screen
```

### APIs

```text
GET  /api/reports/
GET  /api/reports/{id}/
GET  /api/reports/{id}/download/
POST /api/reports/{id}/interpret/
```

### Tasks

- [ ] Create report model
- [ ] Create reports repository
- [ ] Build reports list
- [ ] Build report detail
- [ ] Build secure download flow
- [ ] Build open PDF action
- [ ] Build ask-AI-about-report action

---

## 13. Prescription Feature Tasks

### Screens

```text
Prescription List Screen
Prescription Detail Screen
Prescription Download Screen
Prescription Explanation Screen
```

### APIs

```text
GET  /api/prescriptions/
GET  /api/prescriptions/{id}/
GET  /api/prescriptions/{id}/download/
POST /api/prescriptions/{id}/explain/
```

### Tasks

- [ ] Create prescription model
- [ ] Create prescriptions repository
- [ ] Build prescription list
- [ ] Build prescription detail
- [ ] Build secure download flow
- [ ] Build open PDF action
- [ ] Build ask-AI-about-prescription action

---

## 14. Invoice Feature Tasks

### Screens

```text
Invoice List Screen
Invoice Detail Screen
Invoice Download Screen
```

### APIs

```text
GET /api/invoices/
GET /api/invoices/{id}/download/
```

### Tasks

- [ ] Create invoice model
- [ ] Create invoice repository
- [ ] Build invoice list
- [ ] Build invoice detail
- [ ] Build invoice download
- [ ] Build open PDF action

---

## 15. Ambulance and Emergency Tasks

### Ambulance APIs

```text
POST /api/ambulance/request/
GET  /api/ambulance/requests/
```

### Emergency API

```text
GET /api/emergency-contact/
```

### Tasks

- [ ] Build ambulance request form
- [ ] Build pickup address input
- [ ] Build destination address input
- [ ] Build contact number input
- [ ] Submit ambulance request
- [ ] Build emergency call button
- [ ] Use `tel:` launcher for emergency number

---

## 16. API Client Tasks

Use Dio.

### Required Core Files

```text
core/api/api_client.dart
core/api/api_endpoints.dart
core/api/interceptors/auth_interceptor.dart
core/api/interceptors/error_interceptor.dart
core/storage/secure_storage_service.dart
```

### Tasks

- [ ] Create base API client
- [ ] Add base URL config
- [ ] Add authorization header
- [ ] Add refresh token handling
- [ ] Add global error handling
- [ ] Add timeout handling
- [ ] Add logging in development only

---

## 17. State Management Tasks

Use Riverpod.

Required providers:

```text
authProvider
chatProvider
doctorProvider
appointmentProvider
diagnosticsProvider
reportsProvider
prescriptionsProvider
invoicesProvider
profileProvider
```

Tasks:

- [ ] Create async state models
- [ ] Handle loading state
- [ ] Handle empty state
- [ ] Handle error state
- [ ] Handle retry action

---

## 18. Navigation Tasks

Use GoRouter.

Routes:

```text
/
 /login
 /home
 /doctors
 /doctors/:id
 /appointments
 /diagnostics/labs
 /diagnostics/labs/:id/tests
 /reports
 /prescriptions
 /invoices
 /ambulance
 /profile
```

Tasks:

- [ ] Create route constants
- [ ] Create auth redirect logic
- [ ] Protect logged-in routes
- [ ] Redirect unknown routes
- [ ] Add deep-link readiness later

---

## 19. Design System Tasks

### Theme

Use Material 3.

Required:

- Primary color
- Secondary color
- Danger color
- Success color
- Warning color
- Text styles
- Card style
- Button style
- Input style

### Shared Widgets

```text
AppButton
AppTextField
AppCard
LoadingView
ErrorView
EmptyView
StatusBadge
PriceText
SectionTitle
ServiceShortcutCard
ConfirmationCard
```

---

## 20. Safety UX Requirements

For medical chat:

- Show emergency warning for severe symptoms.
- Do not present AI answer as final diagnosis.
- Show disclaimer in health guidance.
- Confirm before booking.
- Confirm before payment.
- Never show another user's data.
- Use clear button labels.

Example:

```text
This AI assistant does not replace a doctor. For severe or emergency symptoms, call emergency service immediately.
```

---

## 21. Development Phases

### Phase 1 — Flutter Setup

- [ ] Clean project structure
- [ ] Add packages
- [ ] Configure theme
- [ ] Configure router
- [ ] Configure API client
- [ ] Configure secure storage

### Phase 2 — Authentication

- [ ] Login UI
- [ ] Login API
- [ ] Token storage
- [ ] Auth redirect
- [ ] Logout

### Phase 3 — Chat Home

- [ ] Chat layout
- [ ] Service shortcut buttons
- [ ] Message input
- [ ] Chat bubbles
- [ ] Dynamic card renderer

### Phase 4 — Manual Doctor Booking

- [ ] Doctor list
- [ ] Doctor details
- [ ] Slot selection
- [ ] Appointment draft
- [ ] Appointment confirmation

### Phase 5 — Manual Diagnostic Booking

- [ ] Lab list
- [ ] Test list
- [ ] Diagnostic cart
- [ ] Diagnostic order draft
- [ ] Diagnostic order confirmation

### Phase 6 — Documents

- [ ] Reports list/download
- [ ] Prescriptions list/download
- [ ] Invoices list/download

### Phase 7 — AI-Agent Integration

- [ ] Chat API integration
- [ ] AI tool card rendering
- [ ] Confirm/cancel job flow
- [ ] AI-created appointment draft
- [ ] AI-created diagnostic order draft

### Phase 8 — Production Polish

- [ ] Error handling
- [ ] Empty states
- [ ] Loading skeletons
- [ ] App icon
- [ ] Splash screen
- [ ] Android build
- [ ] Release APK/AAB

---

## 22. First Codex Prompt for Flutter

Use this prompt after the backend API contract is stable:

```text
Build a Flutter healthcare app using feature-first architecture.

Use:
- Material 3
- Riverpod
- Dio
- GoRouter
- Flutter Secure Storage

Create:
- Login screen
- Chat-first home screen
- Service shortcut chips
- Doctor list screen
- Doctor detail screen
- Appointment slot selector
- Diagnostic lab list screen
- Diagnostic test list screen
- Reports list screen
- Prescriptions list screen
- Invoices list screen

Do not use mock data except temporary placeholder models.
Prepare all repositories for Django REST API integration.
Create clean reusable widgets.
```

---

## 23. MVP Flutter Scope

First mobile MVP:

```text
Login
Chat home
Doctor cards
Doctor list
Doctor details
Appointment booking
Lab list
Test list
Diagnostic cart
Reports list
Prescriptions list
Invoices list
Emergency call button
```

AI assistant can initially only:

```text
Suggest doctors
Suggest tests
Create draft appointment
Create draft diagnostic order
```

Final booking must require user confirmation.
