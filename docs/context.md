# Group Trip Expense Splitter - Development Context

## Project Overview

A mobile-first expense splitting application for group travel with dual interfaces:
- **Admin Interface**: Native Flutter app (iOS/Android) 
- **Member Interface**: Progressive Web App (PWA)
- **Backend**: Google Cloud Platform with Firebase services

## Development Environment Setup (macOS)

### Prerequisites
```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Node.js and npm
brew install node

# Install Flutter
brew install --cask flutter

# Install Android Studio
brew install --cask android-studio

# Install Xcode (from App Store)
# Install Xcode Command Line Tools
xcode-select --install

# Install Firebase CLI
npm install -g firebase-tools

# Install CocoaPods (for iOS dependencies)
sudo gem install cocoapods
```

### VSCode Extensions
```json
{
  "recommendations": [
    "dart-code.flutter",
    "dart-code.dart-code",
    "ms-vscode.vscode-typescript-next",
    "bradlc.vscode-tailwindcss",
    "firebase.vscode-firestore-rules",
    "ms-vscode.vscode-json",
    "esbenp.prettier-vscode",
    "ms-vscode.vscode-eslint",
    "formulahendry.auto-rename-tag",
    "christian-kohler.path-intellisense"
  ]
}
```

### Project Structure
```
group-trip-splitter/
├── admin-app/                 # Flutter native app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/
│   │   ├── screens/
│   │   ├── widgets/
│   │   ├── services/
│   │   └── utils/
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
├── member-pwa/               # React/Vue PWA
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   ├── services/
│   │   └── utils/
│   ├── public/
│   └── package.json
├── backend/                  # Cloud Functions
│   ├── functions/
│   │   ├── src/
│   │   │   ├── index.ts
│   │   │   ├── triggers/
│   │   │   ├── api/
│   │   │   └── utils/
│   │   └── package.json
│   └── firestore.rules
├── shared/                   # Shared types/models
│   ├── types/
│   └── utils/
└── docs/
    ├── api.md
    ├── deployment.md
    └── architecture.md
```

## Tech Stack

### Admin App (Flutter)
```yaml
# pubspec.yaml dependencies
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  firebase_messaging: ^14.7.10
  firebase_storage: ^11.5.6
  provider: ^6.1.1
  go_router: ^12.1.3
  flutter_riverpod: ^2.4.9
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1
  image_picker: ^1.0.4
  file_picker: ^6.1.1
  local_auth: ^2.1.7
  shared_preferences: ^2.2.2
  connectivity_plus: ^5.0.2
  permission_handler: ^11.1.0
```

### Member PWA (React/TypeScript)
```json
{
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "typescript": "^5.3.0",
    "firebase": "^10.7.1",
    "react-router-dom": "^6.20.1",
    "@tanstack/react-query": "^5.12.2",
    "react-hook-form": "^7.48.2",
    "tailwindcss": "^3.3.6",
    "workbox-webpack-plugin": "^7.0.0",
    "react-hot-toast": "^2.4.1"
  }
}
```

### Backend (Node.js/TypeScript)
```json
{
  "dependencies": {
    "firebase-functions": "^4.5.0",
    "firebase-admin": "^11.11.1",
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^7.1.0",
    "joi": "^17.11.0",
    "axios": "^1.6.2",
    "csv-writer": "^1.6.0"
  }
}
```

## Data Models (TypeScript)

```typescript
// shared/types/index.ts

export interface User {
  id: string;
  email: string;
  phone?: string;
  displayName: string;
  role: 'admin' | 'member';
  createdAt: Date;
  lastLoginAt?: Date;
}

export interface Trip {
  id: string;
  name: string;
  origin: string;
  destination: string;
  startDate: Date;
  endDate: Date;
  currency: string;
  status: 'active' | 'closed' | 'archived';
  adminId: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface Member {
  id: string;
  tripId: string;
  userId: string;
  dependentsCount: number;
  joinedAt: Date;
  isActive: boolean;
}

export interface Dependent {
  id: string;
  memberId: string;
  name: string;
  relationship: string;
  createdAt: Date;
}

export interface Category {
  id: string;
  tripId: string;
  name: string;
  createdBy: string;
  isActive: boolean;
  createdAt: Date;
}

export interface Expense {
  id: string;
  tripId: string;
  amount: number;
  currency: string;
  description: string;
  categoryId: string;
  paidBy: string;
  participants: string[]; // member/dependent IDs
  customSplit?: { [userId: string]: number };
  receiptUrl?: string;
  status: 'pending' | 'committed' | 'rejected';
  adminComment?: string;
  createdBy: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface Balance {
  id: string;
  tripId: string;
  memberId: string;
  totalPaid: number;
  totalShare: number;
  netBalance: number; // positive = owed money, negative = owes money
  lastUpdated: Date;
}
```

## Firebase Configuration

### Firestore Security Rules
```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own profile
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Trip access control
    match /trips/{tripId} {
      allow read: if isAuthenticated() && isTripMember(tripId);
      allow write: if isAuthenticated() && isTripAdmin(tripId);
      
      // Members subcollection
      match /members/{memberId} {
        allow read: if isAuthenticated() && isTripMember(tripId);
        allow write: if isAuthenticated() && isTripAdmin(tripId);
      }
      
      // Categories subcollection
      match /categories/{categoryId} {
        allow read: if isAuthenticated() && isTripMember(tripId);
        allow write: if isAuthenticated() && isTripMember(tripId);
      }
    }
    
    // Expenses
    match /expenses/{expenseId} {
      allow read: if isAuthenticated() && isTripMember(resource.data.tripId);
      allow create: if isAuthenticated() && isTripMember(request.resource.data.tripId) 
        && request.auth.uid == request.resource.data.createdBy;
      allow update: if isAuthenticated() && 
        (isTripAdmin(resource.data.tripId) || 
         (request.auth.uid == resource.data.createdBy && resource.data.status == 'pending'));
    }
    
    // Balances (read-only for members, write via Cloud Functions)
    match /balances/{balanceId} {
      allow read: if isAuthenticated() && isTripMember(resource.data.tripId);
    }
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isTripMember(tripId) {
      return exists(/databases/$(database)/documents/trips/$(tripId)/members/$(request.auth.uid));
    }
    
    function isTripAdmin(tripId) {
      return get(/databases/$(database)/documents/trips/$(tripId)).data.adminId == request.auth.uid;
    }
  }
}
```

### Firebase Functions
```typescript
// backend/functions/src/index.ts
import { initializeApp } from 'firebase-admin/app';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onCall } from 'firebase-functions/v2/https';
import { recalculateBalances } from './triggers/balanceCalculator';
import { sendInvitation } from './api/invitations';

initializeApp();

// Trigger balance recalculation when expense is committed
export const onExpenseChange = onDocumentWritten(
  'expenses/{expenseId}',
  async (event) => {
    const expense = event.data?.after?.data();
    if (expense?.status === 'committed') {
      await recalculateBalances(expense.tripId);
    }
  }
);

// API endpoints
export const inviteMember = onCall(async (request) => {
  return await sendInvitation(request.data);
});
```

## Development Commands

### Flutter (Admin App)
```bash
# Navigate to admin app directory
cd admin-app

# Get dependencies
flutter pub get

# Generate code (for freezed/json_annotation)
flutter packages pub run build_runner build

# Run on iOS simulator
flutter run -d ios

# Run on Android emulator
flutter run -d android

# Build for release
flutter build ipa              # iOS
flutter build apk              # Android
```

### PWA (Member App)
```bash
# Navigate to PWA directory
cd member-pwa

# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

### Backend
```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install

# Start emulator for local development
firebase emulators:start

# Deploy functions
firebase deploy --only functions

# Deploy Firestore rules
firebase deploy --only firestore:rules
```

## Key Implementation Guidelines

### State Management (Flutter)
```dart
// Use Riverpod for state management
final tripProvider = StateNotifierProvider<TripNotifier, AsyncValue<List<Trip>>>(
  (ref) => TripNotifier(),
);

class TripNotifier extends StateNotifier<AsyncValue<List<Trip>>> {
  TripNotifier() : super(const AsyncValue.loading()) {
    loadTrips();
  }
  
  Future<void> loadTrips() async {
    try {
      final trips = await TripService().getUserTrips();
      state = AsyncValue.data(trips);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
```

### API Service Pattern
```typescript
// member-pwa/src/services/api.ts
class ApiService {
  private firestore = getFirestore();
  
  async createExpense(expense: CreateExpenseRequest): Promise<string> {
    const docRef = await addDoc(collection(this.firestore, 'expenses'), {
      ...expense,
      status: 'pending',
      createdAt: serverTimestamp(),
      createdBy: auth.currentUser?.uid,
    });
    return docRef.id;
  }
  
  subscribeToTrip(tripId: string, callback: (trip: Trip) => void) {
    return onSnapshot(doc(this.firestore, 'trips', tripId), (doc) => {
      if (doc.exists()) {
        callback({ id: doc.id, ...doc.data() } as Trip);
      }
    });
  }
}
```

### Split Calculation Algorithm
```typescript
// backend/functions/src/utils/splitCalculator.ts
export function calculateSplit(
  amount: number,
  participants: string[],
  dependents: Map<string, number>,
  customSplit?: { [userId: string]: number }
): { [userId: string]: number } {
  
  if (customSplit) {
    return customSplit;
  }
  
  // Calculate total heads (members + dependents)
  const totalHeads = participants.reduce((total, memberId) => {
    return total + 1 + (dependents.get(memberId) || 0);
  }, 0);
  
  const perHead = amount / totalHeads;
  const split: { [userId: string]: number } = {};
  
  participants.forEach(memberId => {
    const memberHeads = 1 + (dependents.get(memberId) || 0);
    split[memberId] = perHead * memberHeads;
  });
  
  return split;
}
```

## Testing Strategy

### Flutter Tests
```dart
// test/services/trip_service_test.dart
void main() {
  group('TripService', () {
    testWidgets('should create trip successfully', (WidgetTester tester) async {
      // Mock Firebase
      setupFirebaseAuthMocks();
      
      final tripService = TripService();
      final trip = await tripService.createTrip(CreateTripRequest(
        name: 'Test Trip',
        // ... other fields
      ));
      
      expect(trip.id, isNotEmpty);
      expect(trip.name, equals('Test Trip'));
    });
  });
}
```

## Deployment Pipeline

### GitHub Actions Workflow
```yaml
# .github/workflows/deploy.yml
name: Deploy
on:
  push:
    branches: [main]

jobs:
  deploy-functions:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '18'
      - run: npm install
        working-directory: backend
      - run: firebase deploy --only functions
        working-directory: backend
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
```

## Security Considerations

1. **Authentication**: Use Firebase Auth with custom claims for RBAC
2. **Data Validation**: Validate all inputs on both client and server
3. **File Upload**: Sanitize and validate receipt uploads
4. **Rate Limiting**: Implement rate limiting for expensive operations
5. **Audit Logging**: Log all critical operations for audit trails

## Performance Optimization

1. **Firestore**: Use compound indexes for complex queries
2. **Images**: Compress receipt images before upload
3. **Caching**: Implement offline-first with Firestore cache
4. **Bundle Size**: Code splitting for PWA, tree shaking for Flutter

