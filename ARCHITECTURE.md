# Architecture Overview

## System Design

Family Pulse uses a **client-server architecture** with Firebase as the backend and Flutter for cross-platform mobile clients.

```
┌─────────────────────────────────────────────────────────────┐
│                     Firebase Cloud                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Firestore DB │  │ Auth Service │  │ Security     │      │
│  │              │  │              │  │ Rules        │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
           ▲                    ▲                    ▲
           │                    │                    │
    Real-time Sync         Auth Flow          Access Control
           │                    │                    │
           ▼                    ▼                    ▼
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Application                       │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              App State (Provider)                     │  │
│  │  - User Management                                    │  │
│  │  - Family Data                                        │  │
│  │  - Real-time Listeners                               │  │
│  │  - Periodic Sync Timer                               │  │
│  └──────────────────────────────────────────────────────┘  │
│           │                                    │             │
│           ▼                                    ▼             │
│  ┌─────────────────┐              ┌─────────────────┐      │
│  │  UI Screens     │              │ Usage Service   │      │
│  │  - Hub          │              │ (Method Channel)│      │
│  │  - Leaderboard  │              └─────────────────┘      │
│  │  - Streak       │                       │                │
│  │  - Details      │                       ▼                │
│  └─────────────────┘              ┌─────────────────┐      │
│                                    │ Native Android  │      │
│                                    │ MainActivity.kt │      │
│                                    └─────────────────┘      │
└─────────────────────────────────────────────────────────────┘
                                             │
                                             ▼
                                    ┌─────────────────┐
                                    │ UsageStats API  │
                                    │ (Android System)│
                                    └─────────────────┘
```

## Data Models

### User Profile
```dart
{
  "id": "user_uid",
  "name": "John Doe",
  "role": "UserRole.child",
  "familyId": "family_123",
  "todayUsage": 145,  // minutes
  "usageBreakdown": [
    {"appName": "YouTube", "minutes": 60},
    {"appName": "WhatsApp", "minutes": 45}
  ],
  "lastActive": Timestamp
}
```

### Family Document
```dart
{
  "id": "family_123",
  "name": "Smith Family",
  "joinCode": "783099",
  "hostId": "parent_uid",
  "dailyGoal": 120,  // minutes
  "createdAt": Timestamp
}
```

### Streak History (Subcollection)
```dart
families/{familyId}/history/{date}
{
  "date": DateTime(2024, 1, 15),
  "success": true  // All members met goal
}
```

## Key Components

### 1. AppState (State Management)
**Responsibilities:**
- Manages authentication state
- Listens to Firestore changes
- Triggers periodic usage refresh
- Provides data to UI via Provider

**Key Methods:**
- `refreshRealUsageData()`: Fetches from native, uploads to Firestore
- `_listenToFamily()`: Real-time family data subscription
- `_startPeriodicRefresh()`: 10-minute background timer

### 2. UsageService (Native Bridge)
**Responsibilities:**
- Bridges Flutter ↔ Android
- Exposes native methods via MethodChannel

**Methods:**
- `getTodayScreenTime()`: Returns total minutes
- `getAppUsageBreakdown()`: Returns top 20 apps
- `isPermissionGranted()`: Checks Usage Access
- `openSettings()`: Opens permission screen

### 3. MainActivity.kt (Native Logic)
**Responsibilities:**
- Queries Android UsageEvents API
- Calculates precise screen time
- Filters system apps and noise

**Key Algorithm:**
```kotlin
1. Query all events since midnight
2. For each MOVE_TO_FOREGROUND event:
   - Record start time for that app
3. For each MOVE_TO_BACKGROUND event:
   - Calculate duration = end - start
   - Add to app's total time
4. Filter out non-user apps
5. Return aggregated data
```

## Security Model

### Firestore Rules
```javascript
// Users can only read/write their own profile
match /users/{userId} {
  allow read: if request.auth.uid == userId || 
                 isInSameFamily(userId);
  allow write: if request.auth.uid == userId;
}

// Only family members can access family data
match /families/{familyId} {
  allow read: if isFamilyMember(familyId);
  allow create: if request.auth != null;
  allow update: if isFamilyHost(familyId);
}
```

## Performance Optimizations

1. **Firestore Indexes**: Automatic on `familyId` field
2. **Snapshot Listeners**: Only subscribe to relevant family data
3. **Periodic Sync**: 10-minute intervals (not continuous)
4. **Native Calculation**: Screen time computed on-device
5. **Lazy Loading**: UI only renders visible items

## Scalability Considerations

- **Firestore Limits**: Free tier supports ~50K reads/day (sufficient for 10-20 families)
- **Real-time Connections**: Limited to 100 concurrent (adequate for hackathon demo)
- **Storage**: Minimal (text data only, no media)
- **Bandwidth**: Low (only usage numbers sync, not raw events)

## Error Handling

1. **Network Errors**: Graceful fallback with cached data
2. **Permission Denied**: Clear UI prompts to grant access
3. **Auth Failures**: User-friendly error messages
4. **Firestore Offline**: Automatic retry with exponential backoff
5. **Native Crashes**: Try-catch blocks with error reporting

## Testing Strategy

### Manual Testing Checklist
- [ ] Parent can create family
- [ ] Child can join with code
- [ ] Screen time matches Digital Wellbeing
- [ ] Real-time sync works across devices
- [ ] Streak heatmap updates correctly
- [ ] App breakdown shows correct apps
- [ ] Background sync runs every 10 minutes

### Edge Cases Handled
- User without family
- Family with no members
- Child with 0 screen time
- Network disconnection
- Permission revoked mid-session
