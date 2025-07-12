# SplitDine MVP — Developer Specification Document

This document describes the **final, agreed, ready-to-code MVP specification** for SplitDine.  
It is designed for AI coders or human developers to implement consistently.

---

## 📌 App Overview

SplitDine is a collaborative restaurant bill-splitting app.  
It allows groups to:

- Plan upcoming meals
- Share a join code
- Enter items (scanned or manual)
- Assign items fairly (including shared dishes/tips)
- View clear split summaries
- Mark payments manually

---

## ✅ App Structure

1. **App Launch & Login/Register/Guest Name**
2. **Session Lobby**
   - Splits sessions into *Upcoming* and *Past* purely by session date
3. **Create Session** (Organiser)
4. **Join Session** (Guest)
5. **Session View**
   - Single consistent interface for all sessions

---

## ✅ Session Rules

- **Date is the only source of truth for session state**:
  - **Upcoming**: session date ≥ today
  - **Past**: session date < today

- **Editable only if date is today or future**:
  - After session date, **all views are read-only**

- **No "Active/Complete/Draft" status field in database** needed

---

## ✅ User Roles

- **Organiser**:
  - Creates sessions
  - Can edit session details before the date
  - Can scan receipt
  - Full item assignment control
  - Can mark anyone as Paid

- **Guest**:
  - Joins session via code/link
  - Can add/delete own items
  - Can assign/unassign themselves to items
  - Can mark themselves as Paid

---

## ✅ Detailed Screen & Section Specs

---

### **1. App Launch & Login/Register/Guest Name**

**Purpose**:
- Identify user before showing Lobby

**Features**:
- Login with email/password
- Register with email/password
- Continue as Guest (enter name only)
- Minimum requirement: user must have *display name*

---

### **2. Session Lobby**

**Purpose**:
- Home screen showing all sessions user is involved in
- Splits sessions by *Upcoming* and *Past* using date

**Data Needed**:
- User ID
- Sessions list:
  - Session Name
  - Location
  - Date/Time
  - Description
  - Code
  - Organiser/Guest role

**User Actions**:
- View *Upcoming* and *Past* sessions
- Tap to open any session (always goes to **Session View**)
- Create New Session (Organiser)
- Join Session (Guest)

**Key Rules**:
- **Date is mandatory** when creating session
- Must be today or future (no creating in past)
- Cannot join session if date is in past

---

### **3A. Create Session (Organiser)**

**Purpose**:
- Define new session for planning

**Data Collected**:
- Session Name (optional)
- **Location** (required)
- **Date/Time** (required)
- Description (optional)
- Auto-generated Session Code
- Organiser ID

**User Actions**:
- Fill form
- Tap **Create Session**
- View generated Code/Link
- Share via WhatsApp etc.

**Validation**:
- Cannot save with past date

**Result**:
- New session appears in Lobby *Upcoming* list

---

### **3B. Join Session (Guest)**

**Purpose**:
- Join an organiser's planned session

**User Actions**:
- Enter **Session Code** (or tap shared link)
- Tap **Join**

**Validation**:
- Cannot join if session date is in the past

**Result**:
- Session added to user's *Upcoming* list

---

### **4. Session View (Single Interface for All Sessions)**

**Key Rule**:
- **Same UI for Upcoming and Past**
- **Editable if date ≥ today**
- **Read-only if date < today**

---

#### **4.1. Session Overview Header**

**Shows**:
- Session Name
- Location
- Date/Time
- Description
- Session Code (with copy button)
- Participants list (Organiser/Guests)

**Permissions**:
- Organiser can edit before date
- Everyone read-only after date

---

#### **4.2. Receipt Entry (Scan / Manual)**

**Purpose**:
- Build the list of bill items

**Features**:
- Organiser:
  - Scan receipt
  - Trigger OCR
  - Add manual items
  - Delete any item
- Guests:
  - Add manual items
  - Delete own items

**Permissions**:
- Entire section read-only after session date

---

#### **4.3. OCR Review & Edit**

**Purpose**:
- Clean up messy scanned items
- Ensure accurate, usable line items

**Features**:
- Organiser:
  - Edit/delete any item
- Guests:
  - Edit/delete own items

**Permissions**:
- Read-only after session date

---

#### **4.4. Item Assignment**

**Purpose**:
- Assign items to participants
- Supports shared items split evenly

**Features**:
- Organiser:
  - Assign/unassign any participant to any item
- Guests:
  - Assign/unassign themselves only
- Supports multi-assignee shared items
- Even cost splitting among assignees
- Manual **Save**/Confirm—no real-time sync required

**Permissions**:
- Entire section read-only after session date

---

#### **4.5. Split Summary**

**Purpose**:
- Show calculated per-person totals
- Transparent final bill split

**Features**:
- Itemised breakdown per participant
- Even split for shared items
- Always view-only

**Available**:
- Always visible, even after session date

---

#### **4.6. Mark as Paid**

**Purpose**:
- Manual tracking of who has paid

**Features**:
- Organiser:
  - Can toggle Paid status for any guest
- Guests:
  - Can toggle their own Paid status

**Permissions**:
- Entire section read-only after session date

---

## ✅ Technical Notes

- Session date is the *only* source of truth for Upcoming vs Past.
- No "status" field needed in database.
- Session View is always the same interface.
- Editing enabled only if date ≥ today.
- Changes saved on user action; **no real-time sync** required for MVP.
- Multiple sessions supported in Lobby (some as organiser, some as guest).

---

## ✅ Summary of Key MVP Rules

- Cannot create or join sessions with a date in the past.
- Date alone determines Lobby split and editability.
- Guests can see all details but have limited editing rights.
- Organiser has full control before the meal date.
- All sections become read-only after the meal date.

