# Product Requirements Document (PRD)
## Group Trip Expense Splitter

---

## 1. Purpose & Scope

This application enables a **Trip Admin** (native mobile app) and **Members** (mobile-web) to track, review, and settle group travel expenses—including support for **Dependents**—with real-time cost splitting and transparent balances. The backend will be deployed on **Google Cloud Platform (GCP)** using **Firebase** services.

### 1.1 Target Audience
Friends, families, or colleagues undertaking shared trips who need hassle-free expense tracking and settlement.

### 1.2 Out-of-Scope
- In-app payments / money transfer APIs
- Multi-currency support (single currency assumed per trip)
- Desktop-focused UI (mobile-first only)

---

## 2. User Roles & Permissions

| **Role** | **Access Method** | **Key Capabilities** |
|----------|------------------|---------------------|
| **Admin** | Native Flutter app (Android/iOS) | Trip lifecycle, member & category management, expense approval, dashboards, export |
| **Member** | Responsive web app (PWA on Firebase Hosting) | Expense entry, dependent management, view summaries & settlements |
| **Dependent** | --- | No login; linked to parent member; counted in splits |

RBAC will be enforced via **Firebase Auth custom claims**.

---

## 3. Functional Requirements

### 3.1 Authentication & Onboarding

- **Admin Login**: Email + password or phone OTP (Firebase Auth) with optional biometric unlock
- **Member Invitation**: Admin enters WhatsApp#/email → system sends unique magic link via WhatsApp Cloud API or email → member sets password and profile
- **Session Handling**: Refresh tokens; auto-logout after 14 days of inactivity

### 3.2 Trip Management *(Admin)*

1. **Create / Edit Trip**: Name, origin, destination, start/end dates, default currency, visibility
2. **Close Trip**: Lock expense additions; trigger final settlement snapshot and CSV export
3. **Archive Trip**: Move closed trips to read-only storage

### 3.3 Member & Dependent Management

- **Add / Remove Member** with WhatsApp#/email
- **Add Dependent** (member only): Name + relationship. Immediate effect; tied to parent in all calculations

### 3.4 Expense Workflow

| **Step** | **Member Action** | **Admin Action** |
|----------|------------------|------------------|
| 1 | Add expense: amount, category, payer, participants, receipt photo (optional). Status = *Pending* | --- |
| 2 | --- | Review queue: approve/reject individually or in bulk; optional comment |
| 3 | --- | Approval sets Status = *Committed* → triggers real-time recalculation (Cloud Function) |
| 4 | --- | Rejection notifies member for correction |

- **Categories**: Admin-defined master list; members may propose ad-hoc categories that become active upon approval

### 3.5 Real-Time Split & Settlement

- **Algorithm** (even split default):
  - *perHead = amount / (# selected members + dependents)*
  - Dependent share rolls up to parent
  - Balances stored per member as *paid*, *share*, *net*

- **Custom Splits**: UI to adjust percentage or fixed amounts; stored in expense document
- **Consistency**: Cloud Function triggers ensure recalculation on every committed expense mutation

### 3.6 Dashboards & Reports

- **Member Dashboard**: Personal paid/owed, category breakdown, expense feed
- **Admin Dashboard**: Group totals, pending count, per-member matrix, export (CSV/Excel via Cloud Functions + Cloud Storage signed URL)

### 3.7 Notifications

- In-app/Web push (Firebase Cloud Messaging) for expense review outcomes, new committed expenses, trip closure
- Optional WhatsApp alerts for major events

### 3.8 Audit & Logs

- Immutable log of CRUD actions on trips, members, expenses (Firestore exports to BigQuery daily)

---

## 4. Data Model (Firestore, top-level collections)

```
users/{userId}
└─ role: "admin" | "member"

trips/{tripId}
├─ meta: name, origin, destination, dates, status
├─ members/{memberId}: ref → users/{userId}, dependentsCount
└─ categories/{catId}: name, createdBy

expenses/{expenseId}
├─ tripId, createdBy, status (pending|committed|rejected)
├─ amount, currency, categoryId, paidBy
├─ participants: [userId|dependentId]
└─ customSplit: { userId: share }
```

---

## 5. Non-Functional Requirements

| **Aspect** | **Requirement** |
|------------|----------------|
| **Performance** | < 2s p95 for API responses, < 1s recalculation for ≤ 50 participants |
| **Reliability** | 99.9% monthly uptime; multi-zone Firestore; Cloud Functions deployed across 2 regions |
| **Security** | End-to-end TLS; Firestore security rules; IAM-scoped service accounts; encrypted storage |
| **Scalability** | Tested to 10K expenses per trip & 100 concurrent users; horizontal autoscaling via Cloud Run |
| **Accessibility** | WCAG 2.1 AA compliance; RTL language ready |
| **Localization** | Framework for i18n; English default |
| **Offline** | Firestore local cache for read; queue write-behind when offline (Member PWA) |

---

## 6. Technical Architecture

```
┌──────────┐ HTTPS ┌────────────────────────┐
│Flutter App│◀──────────▶│ Firebase Auth        │
└──────────┘          └────────────────────────┘
     ▲                           ▲
     │                           │
     │ HTTPS                     │ gRPC / REST
     ▼                           ▼
┌─────────────┐ Cloud Run ┌─────────────────────┐
│ Web (PWA)   │◀──────────▶ │ Firestore (DB)     │
└─────────────┘          └─────────────────────┘
     ▲                           ▲
     │                           │
     │Cloud Functions events     │
     ▼                           ▼
┌───────────────────────────────┐
│ Split Calc Cloud Function     │
└───────────────────────────────┘
```

- **Hosting**: Firebase Hosting (member PWA) + Google Play / App Store (Flutter build)
- **Business Logic**: Cloud Functions (Node.js/TS) & Cloud Run (Python) for heavy batch exports
- **Storage**: Firestore (NoSQL), Cloud Storage (receipts), BigQuery (analytics)

---

## 7. User Flows *(Happy Path)*

1. **Admin** installs app → signs up → creates Trip A → adds 4 members
2. Member receives WhatsApp link → sets password → logs expense → awaits approval
3. Admin approves expense → split recalculates → members receive push notification
4. Trip ends → Admin closes trip → system generates settlement CSV & signed URL

---

## 8. Risks & Mitigations

| **Risk** | **Impact** | **Mitigation** |
|----------|------------|----------------|
| Excess pending expenses overwhelm Admin | Delays settlement | Batch approve, filters, reminder notifications |
| WhatsApp delivery failure | Member onboarding blocked | Email fallback + link expiry extension |
| Calculation bugs | Incorrect balances | Unit & integration tests; BigQuery audit comparison |
| Vendor lock-in (Firebase) | Migration cost | Define clear repository interfaces; export scripts |

---

*Document Version: 1.0*  
*Last Updated: [Date]*  
*Owner: Product Team*