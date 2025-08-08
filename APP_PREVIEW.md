# 📱 App Preview - Group Trip Expense Splitter

## 🎯 What You'll See When Testing

### 🔐 Login Screen
```
┌─────────────────────────────────────┐
│  💰 Group Trip Expense Splitter     │
│           Admin Login               │
│                                     │
│  📧 Email: [________________]       │
│  🔒 Password: [____________]        │
│                                     │
│  [        LOGIN        ]           │
│                                     │
│  Forgot Password?                   │
│  Don't have an account? Sign Up     │
└─────────────────────────────────────┘
```

### 🏠 Home Screen (No Active Trip)
```
┌─────────────────────────────────────┐
│ Active Trip                    🔄 ➕ │
├─────────────────────────────────────┤
│                                     │
│        🧳 No Active Trip            │
│                                     │
│   Create your first trip or        │
│   activate an existing one          │
│                                     │
│  [Create Trip] [View All]          │
│                                     │
├─────────────────────────────────────┤
│ Recent Expenses                     │
│                                     │
│        📄 No Expenses Yet           │
│                                     │
│   Add your first expense to        │
│   get started                       │
│                                     │
│  [        Add Expense        ]     │
└─────────────────────────────────────┘
│ 🏠 Home │ 🧳 Trips │ 💰 Expenses │ ⚙️ │
```

### 🏠 Home Screen (With Active Trip)
```
┌─────────────────────────────────────┐
│ Active Trip                    🔄 ➕ │
├─────────────────────────────────────┤
│ ⭐ ACTIVE TRIP            [LIVE]    │
│                                     │
│ Goa Beach Trip                      │
│ Mumbai → Goa                        │
│ Dec 15 - Dec 20, 2023              │
│                                     │
│ ₹19.2K    4        8               │
│ Total   Members  Expenses           │
│                                     │
│ [Add Expense] [View Details]       │
├─────────────────────────────────────┤
│ Recent Expenses            View All │
│                                     │
│ 🏨 Beach Resort Booking            │
│    Accommodation • Today            │
│    👤 Paid by John          ₹8,500  │
│                            [Split]  │
│                                     │
│ 🍽️ Seafood Dinner                  │
│    Food • Today                     │
│    👤 Paid by John          ₹2,400  │
│                            [Split]  │
└─────────────────────────────────────┘
│ 🏠 Home │ 🧳 Trips │ 💰 Expenses │ ⚙️ │
```

### 🧳 All Trips Screen
```
┌─────────────────────────────────────┐
│ All Trips                           │
├─────────────────────────────────────┤
│ ℹ️ Only one trip can be active at   │
│   a time                            │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ Goa Beach Trip        [ACTIVE]  │ │
│ │ Mumbai → Goa                    │ │
│ │ Dec 15 - Dec 20, 2023          │ │
│ │                                 │ │
│ │ ₹19.2K   4      8              │ │
│ │ Total  Members Expenses         │ │
│ │                                 │ │
│ │ [Add Expense] [View Details]   │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Kerala Backwaters    [CLOSED]   │ │
│ │ Mumbai → Kerala                 │ │
│ │ Nov 10 - Nov 15, 2023          │ │
│ │                                 │ │
│ │ ₹15.8K   3      12             │ │
│ │ Total  Members Expenses         │ │
│ │                                 │ │
│ │ [Add Expense] [View Details]   │ │
│ └─────────────────────────────────┘ │
│                                     │
│                            [+ Trip] │
└─────────────────────────────────────┘
│ 🏠 Home │ 🧳 Trips │ 💰 Expenses │ ⚙️ │
```

### 💰 Expenses Screen
```
┌─────────────────────────────────────┐
│ Expenses                         ➕  │
├─────────────────────────────────────┤
│           Total Expenses            │
│              ₹19,200                │
│                                     │
│   Total    Pending   Approved       │
│     8         2         6           │
├─────────────────────────────────────┤
│ 🏨 Beach Resort Booking      ✅     │
│    ₹8,500 • 2h ago                 │
│    Paid by John                     │
│                                     │
│ 🍽️ Seafood Dinner            ⏳     │
│    ₹2,400 • 4h ago                 │
│    Paid by Sarah                    │
│                                     │
│ 🚗 Taxi to Airport           ✅     │
│    ₹1,200 • 1d ago                 │
│    Paid by Mike                     │
│                                     │
│ 🎬 Movie Tickets             ❌     │
│    ₹800 • 2d ago                   │
│    Paid by John                     │
└─────────────────────────────────────┘
│ 🏠 Home │ 🧳 Trips │ 💰 Expenses │ ⚙️ │
```

### ⚙️ Settings Screen
```
┌─────────────────────────────────────┐
│ Settings                            │
├─────────────────────────────────────┤
│        👤 John Doe                  │
│      john.doe@email.com             │
│         [ADMIN]                     │
├─────────────────────────────────────┤
│ Account                             │
│ 👤 Edit Profile              >      │
│ 🔒 Change Password           >      │
│                                     │
│ Preferences                         │
│ 🔔 Notifications             >      │
│ 🎨 Theme                     >      │
│ 🌐 Language                  >      │
│                                     │
│ Data & Privacy                      │
│ 📥 Export Data               >      │
│ 🔒 Privacy Policy            >      │
│                                     │
│ Support                             │
│ ❓ Help & FAQ                >      │
│ 💬 Send Feedback             >      │
│ ℹ️ About                     >      │
│                                     │
│ [        Sign Out        ]         │
└─────────────────────────────────────┘
│ 🏠 Home │ 🧳 Trips │ 💰 Expenses │ ⚙️ │
```

### ➕ Add Expense Screen
```
┌─────────────────────────────────────┐
│ ← Add Expense                       │
├─────────────────────────────────────┤
│ 📝 Description                      │
│ [Beach resort booking_______]       │
│                                     │
│ 💰 Amount                           │
│ [8500___________________]           │
│                                     │
│ 📂 Category                         │
│ [🏨 Accommodation        ▼]         │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Split Between                   │ │
│ │                                 │ │
│ │ Participant selection           │ │
│ │ coming soon                     │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Receipt (Optional)              │ │
│ │                                 │ │
│ │ [📷 Add Receipt]                │ │
│ └─────────────────────────────────┘ │
│                                     │
│ [        Add Expense        ]      │
└─────────────────────────────────────┘
```

### 🧳 Create Trip Screen
```
┌─────────────────────────────────────┐
│ ← Create Trip                       │
├─────────────────────────────────────┤
│ 🧳 Trip Name                        │
│ [Goa Beach Trip_________]           │
│                                     │
│ 🛫 Origin                           │
│ [Mumbai_________________]           │
│                                     │
│ 🛬 Destination                      │
│ [Goa____________________]           │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Trip Dates                      │ │
│ │                                 │ │
│ │ 📅 Start Date                   │ │
│ │    Dec 15, 2023                 │ │
│ │                                 │ │
│ │ 📅 End Date                     │ │
│ │    Dec 20, 2023                 │ │
│ │                                 │ │
│ │ ⏰ Duration: 6 days              │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Currency                        │ │
│ │ [💰 INR - Indian Rupee    ▼]    │ │
│ └─────────────────────────────────┘ │
│                                     │
│ [        Create Trip        ]      │
└─────────────────────────────────────┘
```

## 🎨 Visual Features

### Design Elements
- **Primary Color**: Blue (#2196F3)
- **Success Color**: Green (#4CAF50)
- **Warning Color**: Orange (#FF9800)
- **Error Color**: Red (#F44336)
- **Live Indicator**: Animated green dot with "LIVE" text

### Animations
- Smooth screen transitions
- Loading spinners
- Pull-to-refresh animations
- Button press feedback
- Card hover effects

### Responsive Design
- Adapts to different screen sizes
- Proper spacing and padding
- Touch-friendly button sizes
- Readable text on all devices

## 🚀 Interactive Features

### Navigation
- Bottom tab navigation
- Smooth transitions between screens
- Back button support
- Deep linking ready

### Forms
- Real-time validation
- Error message display
- Loading states during submission
- Success feedback

### Lists
- Pull-to-refresh
- Smooth scrolling
- Empty states
- Loading indicators

### Cards
- Tap to navigate
- Visual feedback
- Status indicators
- Action buttons

---

This preview shows what users will experience when testing the app on iOS and Android devices. The interface is clean, intuitive, and follows Material Design principles while maintaining a consistent brand identity.
