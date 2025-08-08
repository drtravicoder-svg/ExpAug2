# UI Screen References

## Home Screen (Active Trip View)

### Key Components
1. App Bar
   - Title: "Active Trip"
   - Refresh button (top right)
   - Add button (top right)

2. Trip Card
   - Status badge: "ACTIVE TRIP" with star icon and "LIVE" indicator
   - Trip title: "Goa Beach Trip"
   - Subtitle: "Amazing beach vacation with friends"
   - Stats row:
     - Total Expenses: ₹19200
     - Members: 4
     - Expenses Count: 8
   - Action buttons:
     - "Add Expense" (primary)
     - "View Details" (secondary)

3. Recent Expenses Section
   - Header with "Recent Expenses" title
   - Subtitle: "Latest expenses from your active trip"
   - "View All" link
   - Expense list items:
     - Beach Resort Booking (₹8500)
       - Category icon
       - "Accommodation" type
       - Timestamp: "Today"
       - "Paid by John"
       - "Split" indicator
     - Seafood Dinner (₹2400)
       - Similar structure as above

4. Bottom Navigation
   - Home
   - All Trips
   - Expenses
   - Settings

## All Trips Screen

### Key Components
1. App Bar
   - Title: "All Trips"

2. Info Banner
   - Message: "Only one trip can be active at a time"

3. Trip Cards List
   a) Active Trip (Blue card)
      - "Goa Beach Trip" with "ACTIVE" badge
      - Description
      - Stats:
        - Total Expenses: ₹19200
        - Members: 4
        - Status: Active
      - Actions: "Add Expense" and "View Details"

   b) Completed Trip (Gray card)
      - "Mountain Adventure"
      - "Hiking and camping in the mountains"
      - Stats:
        - Total Expenses: ₹8500
        - Members: 3
        - Status: Completed
      - Same action buttons

   c) Planning Trip (Gray card)
      - "City Break"
      - "Weekend getaway to explore the city"
      - Stats:
        - Total Expenses: ₹6200
        - Members: 2
        - Status: Planning
      - Same action buttons

4. Create Trip FAB
   - Floating Action Button with "+" icon
   - Label: "Create Trip"

5. Bottom Navigation
   - Same as Home screen

## Design Specifications

### Color Scheme
- Primary Blue: #2196F3 (Active trip cards, buttons)
- Inactive Gray: #9E9E9E (Completed/Planning trip cards)
- Text Colors:
  - Primary: #FFFFFF (on blue)
  - Secondary: rgba(255,255,255,0.7)
  - Dark: #000000 (on white)

### Typography
- Headers: Bold, 24sp
- Subtitles: Regular, 16sp
- Stats: Semi-bold, 20sp
- Button text: Medium, 14sp

### Layout
- Card Padding: 16dp
- Content Spacing: 8dp
- Section Spacing: 24dp
- Border Radius: 12dp (cards)

### Interactive Elements
- Buttons:
  - Primary: Filled, rounded corners
  - Secondary: Outlined, rounded corners
- Cards: Elevated with subtle shadow
- Bottom Nav: Fixed position, equal width items

### Status Indicators
- Live: Green pill badge
- Active: Blue text
- Completed: Gray text
- Planning: Gray text

This reference document captures the key UI elements and specifications from the provided screens for implementation in the Flutter admin app.
