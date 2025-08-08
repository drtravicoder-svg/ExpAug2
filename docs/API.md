# API Documentation
## Group Trip Expense Splitter

---

## 🔐 Authentication

All API endpoints require authentication via Firebase Auth. Include the ID token in the Authorization header:

```http
Authorization: Bearer <firebase-id-token>
```

### Authentication Endpoints

#### Admin Login
```http
POST /auth/admin/login
Content-Type: application/json

{
  "email": "admin@example.com",
  "password": "securepassword"
}
```

#### Member Magic Link
```http
POST /auth/member/magic-link
Content-Type: application/json

{
  "contact": "+1234567890", // WhatsApp number or email
  "tripId": "trip_12345",
  "invitedBy": "admin_user_id"
}
```

---

## 🚗 Trip Management

### Create Trip
```http
POST /api/trips
Content-Type: application/json
Authorization: Bearer <admin-token>

{
  "name": "European Adventure 2024",
  "origin": "New York",
  "destination": "Paris",
  "startDate": "2024-06-01T00:00:00Z",
  "endDate": "2024-06-15T23:59:59Z",
  "currency": "EUR",
  "visibility": "private"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "tripId": "trip_abc123",
    "name": "European Adventure 2024",
    "origin": "New York",
    "destination": "Paris",
    "startDate": "2024-06-01T00:00:00Z",
    "endDate": "2024-06-15T23:59:59Z",
    "currency": "EUR",
    "status": "active",
    "adminId": "admin_user_id",
    "createdAt": "2024-03-15T10:30:00Z",
    "updatedAt": "2024-03-15T10:30:00Z"
  }
}
```

### Get Trip Details
```http
GET /api/trips/{tripId}
Authorization: Bearer <token>
```

### Update Trip
```http
PUT /api/trips/{tripId}
Content-Type: application/json
Authorization: Bearer <admin-token>

{
  "name": "Updated Trip Name",
  "endDate": "2024-06-20T23:59:59Z"
}
```

### Close Trip
```http
POST /api/trips/{tripId}/close
Authorization: Bearer <admin-token>
```

### Archive Trip
```http
POST /api/trips/{tripId}/archive
Authorization: Bearer <admin-token>
```

---

## 👥 Member Management

### Add Member to Trip
```http
POST /api/trips/{tripId}/members
Content-Type: application/json
Authorization: Bearer <admin-token>

{
  "contact": "+1234567890", // WhatsApp or email
  "name": "John Doe",
  "role": "member"
}
```

### Get Trip Members
```http
GET /api/trips/{tripId}/members
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "memberId": "member_123",
      "userId": "user_456",
      "displayName": "John Doe",
      "email": "john@example.com",
      "phone": "+1234567890",
      "dependentsCount": 2,
      "joinedAt": "2024-03-15T12:00:00Z",
      "isActive": true
    }
  ]
}
```

### Remove Member
```http
DELETE /api/trips/{tripId}/members/{memberId}
Authorization: Bearer <admin-token>
```

---

## 👶 Dependent Management

### Add Dependent
```http
POST /api/trips/{tripId}/members/{memberId}/dependents
Content-Type: application/json
Authorization: Bearer <member-token>

{
  "name": "Emma Doe",
  "relationship": "daughter",
  "age": 8
}
```

### Get Dependents
```http
GET /api/trips/{tripId}/members/{memberId}/dependents
Authorization: Bearer <token>
```

### Remove Dependent
```http
DELETE /api/trips/{tripId}/members/{memberId}/dependents/{dependentId}
Authorization: Bearer <member-token>
```

---

## 💰 Expense Management

### Create Expense
```http
POST /api/expenses
Content-Type: application/json
Authorization: Bearer <token>

{
  "tripId": "trip_abc123",
  "amount": 150.50,
  "currency": "EUR",
  "description": "Dinner at Italian restaurant",
  "categoryId": "cat_food",
  "paidBy": "user_456",
  "participants": ["user_456", "user_789", "dependent_101"],
  "receiptUrl": "https://storage.googleapis.com/receipts/receipt_123.jpg",
  "customSplit": {
    "user_456": 75.25,
    "user_789": 75.25
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "expenseId": "expense_xyz789",
    "tripId": "trip_abc123",
    "amount": 150.50,
    "currency": "EUR",
    "description": "Dinner at Italian restaurant",
    "categoryId": "cat_food",
    "paidBy": "user_456",
    "participants": ["user_456", "user_789", "dependent_101"],
    "customSplit": {
      "user_456": 75.25,
      "user_789": 75.25
    },
    "status": "pending",
    "createdBy": "user_456",
    "createdAt": "2024-03-15T19:30:00Z"
  }
}
```

### Get Trip Expenses
```http
GET /api/trips/{tripId}/expenses
Authorization: Bearer <token>

Query Parameters:
- status: pending|committed|rejected
- category: category_id
- paidBy: user_id
- limit: number (default: 50)
- offset: number (default: 0)
```

### Approve/Reject Expense (Admin only)
```http
PUT /api/expenses/{expenseId}/status
Content-Type: application/json
Authorization: Bearer <admin-token>

{
  "status": "committed", // or "rejected"
  "adminComment": "Looks good, approved!"
}
```

### Bulk Approve Expenses (Admin only)
```http
PUT /api/expenses/bulk-approve
Content-Type: application/json
Authorization: Bearer <admin-token>

{
  "expenseIds": ["expense_1", "expense_2", "expense_3"],
  "status": "committed",
  "adminComment": "Batch approved"
}
```

---

## 🏷️ Category Management

### Get Trip Categories
```http
GET /api/trips/{tripId}/categories
Authorization: Bearer <token>
```

### Create Category
```http
POST /api/trips/{tripId}/categories
Content-Type: application/json
Authorization: Bearer <token>

{
  "name": "Transportation",
  "icon": "car",
  "color": "#3B82F6"
}
```

### Update Category (Admin only)
```http
PUT /api/trips/{tripId}/categories/{categoryId}
Content-Type: application/json
Authorization: Bearer <admin-token>

{
  "name": "Updated Category Name",
  "isActive": true
}
```

---

## 💳 Balance & Settlement

### Get Trip Balances
```http
GET /api/trips/{tripId}/balances
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "tripId": "trip_abc123",
    "currency": "EUR",
    "totalAmount": 1250.75,
    "balances": [
      {
        "memberId": "user_456",
        "displayName": "John Doe",
        "totalPaid": 500.00,
        "totalShare": 416.92,
        "netBalance": 83.08,
        "lastUpdated": "2024-03-15T20:15:00Z"
      },
      {
        "memberId": "user_789",
        "displayName": "Jane Smith",
        "totalPaid": 200.00,
        "totalShare": 416.92,
        "netBalance": -216.92,
        "lastUpdated": "2024-03-15T20:15:00Z"
      }
    ],
    "settlements": [
      {
        "from": "user_789",
        "to": "user_456",
        "amount": 216.92,
        "currency": "EUR"
      }
    ]
  }
}
```

### Get Member Balance
```http
GET /api/trips/{tripId}/members/{memberId}/balance
Authorization: Bearer <token>
```

---

## 📊 Reports & Export

### Generate Trip Report
```http
POST /api/trips/{tripId}/export
Content-Type: application/json
Authorization: Bearer <admin-token>

{
  "format": "csv", // or "excel"
  "includeReceipts": true,
  "dateRange": {
    "startDate": "2024-06-01T00:00:00Z",
    "endDate": "2024-06-15T23:59:59Z"
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "exportId": "export_123",
    "downloadUrl": "https://storage.googleapis.com/exports/trip_report_abc123.csv",
    "expiresAt": "2024-03-16T10:30:00Z",
    "fileSize": 1024000
  }
}
```

### Get Trip Statistics
```http
GET /api/trips/{tripId}/statistics
Authorization: Bearer <token>
```

---

## 🔔 Notifications

### Send Push Notification
```http
POST /api/notifications/send
Content-Type: application/json
Authorization: Bearer <admin-token>

{
  "tripId": "trip_abc123",
  "recipients": ["user_456", "user_789"],
  "type": "expense_approved",
  "title": "Expense Approved",
  "body": "Your dinner expense has been approved",
  "data": {
    "expenseId": "expense_xyz789"
  }
}
```

### Get User Notifications
```http
GET /api/users/{userId}/notifications
Authorization: Bearer <token>
```

---

## 📤 File Upload

### Upload Receipt
```http
POST /api/upload/receipt
Content-Type: multipart/form-data
Authorization: Bearer <token>

{
  "file": <binary-data>,
  "tripId": "trip_abc123",
  "expenseId": "expense_xyz789"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "uploadId": "upload_123",
    "fileUrl": "https://storage.googleapis.com/receipts/receipt_xyz789.jpg",
    "fileName": "restaurant_receipt.jpg",
    "fileSize": 256000,
    "mimeType": "image/jpeg"
  }
}
```

---

## ⚠️ Error Responses

All errors follow this format:

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request parameters",
    "details": {
      "field": "amount",
      "reason": "Amount must be greater than 0"
    },
    "timestamp": "2024-03-15T10:30:00Z"
  }
}
```

### Common Error Codes

| Code | Description | HTTP Status |
|------|-------------|-------------|
| `UNAUTHORIZED` | Invalid or missing auth token | 401 |
| `FORBIDDEN` | Insufficient permissions | 403 |
| `NOT_FOUND` | Resource not found | 404 |
| `VALIDATION_ERROR` | Invalid request data | 400 |
| `TRIP_CLOSED` | Cannot modify closed trip | 400 |
| `INSUFFICIENT_BALANCE` | Cannot perform operation | 400 |
| `RATE_LIMIT_EXCEEDED` | Too many requests | 429 |
| `INTERNAL_ERROR` | Server error | 500 |

---

## 🚦 Rate Limits

| Endpoint Category | Rate Limit | Window |
|------------------|------------|---------|
| Authentication | 10 requests | 1 minute |
| Trip Management | 100 requests | 1 hour |
| Expense Operations | 200 requests | 1 hour |
| File Upload | 50 requests | 1 hour |
| Export Generation | 5 requests | 1 hour |

---

## 📱 Real-time Subscriptions (WebSocket)

### Subscribe to Trip Updates
```javascript
// Connect to WebSocket
const ws = new WebSocket('wss://api.yourdomain.com/ws');

// Subscribe to trip events
ws.send(JSON.stringify({
  type: 'SUBSCRIBE',
  channel: `trip_${tripId}`,
  token: firebaseIdToken
}));

// Listen for updates
ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  switch(data.type) {
    case 'EXPENSE_COMMITTED':
      // Update UI with new expense
      break;
    case 'BALANCE_UPDATED':
      // Update balance display
      break;
    case 'MEMBER_JOINED':
      // Update member list
      break;
  }
};
```

### Available Channels
- `trip_{tripId}` - Trip-wide updates
- `user_{userId}` - User-specific notifications
- `expense_{expenseId}` - Expense status changes

---

## 🧪 Testing

### Test Environment
- **Base URL**: `https://api-dev.yourdomain.com`
- **Test Trip ID**: `test_trip_123`
- **Test Admin Token**: Available in development console

### Postman Collection
Download our [Postman collection](./postman/GroupTripAPI.postman_collection.json) for easy testing.

---

## 📚 SDKs & Libraries

### JavaScript/TypeScript SDK
```bash
npm install @group-trip/api-client
```

```typescript
import { GroupTripClient } from '@group-trip/api-client';

const client = new GroupTripClient({
  baseUrl: 'https://api.yourdomain.com',
  getAuthToken: () => firebase.auth().currentUser?.getIdToken()
});

// Create expense
const expense = await client.expenses.create({
  tripId: 'trip_123',
  amount: 50.00,
  description: 'Lunch'
});
```

### Flutter Dart Package
```yaml
dependencies:
  group_trip_api: ^1.0.0
```

```dart
import 'package:group_trip_api/group_trip_api.dart';

final client = GroupTripApiClient(
  baseUrl: 'https://api.yourdomain.com',
  getAuthToken: () => FirebaseAuth.instance.currentUser?.getIdToken(),
);

// Create trip
final trip = await client.trips.create(CreateTripRequest(
  name: 'Summer Vacation',
  currency: 'USD',
));
```