# 🏸 UTM KRP Sport Court Booking Application

**A Smarter Way to Book. A Better Way to Play.**

A centralized digital sports facility booking system developed for **Kolej Rahman Putra (KRP), Universiti Teknologi Malaysia (UTM)**.

The application aims to replace the existing Google Form-based reservation process with a more efficient, secure and automated booking platform. It provides real-time court availability, UTM student authentication, multiple-facility booking, digital payment tracking and centralized administrative management.

Developed by **Team Never500**.

---

## 📌 Table of Contents

- [Project Overview](#-project-overview)
- [Problem Statement](#-problem-statement)
- [Project Objectives](#-project-objectives)
- [Proposed Solution](#-proposed-solution)
- [Key Features](#-key-features)
- [Supported Sports Facilities](#️-supported-sports-facilities)
- [Target Users](#-target-users)
- [Technology Stack](#-technology-stack)
- [System Architecture](#-system-architecture)
- [Database Design](#-database-design)
- [System Workflow](#-system-workflow)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
- [Development Roadmap](#-development-roadmap)
- [Team Members and Roles](#-team-members-and-roles)
- [GitHub Collaboration](#-github-collaboration)
- [Project Status](#-project-status)
- [Project Vision](#-project-vision)

---

## 🎯 Project Overview

The UTM KRP Sport Court Booking Application is a cross-platform sports facility reservation system designed to improve the existing booking process at Kolej Rahman Putra (KRP), Universiti Teknologi Malaysia.

Currently, the sports facility booking process relies on Google Forms, which creates several operational challenges, including double-bookings, delayed confirmations, manual payment verification and inconvenient booking procedures.

To address these challenges, our team proposes a centralized digital platform that allows eligible UTM students to browse sports facilities, check real-time availability, reserve multiple facilities or time slots and complete online payments.

The system will also provide KRP administrators with a centralized dashboard to manage facilities, monitor reservations, track payments and handle cancellations.

The application will support both mobile devices and web browsers, improving accessibility for the KRP community.

### Project Information

| Item | Description |
|---|---|
| Project Name | UTM KRP Sport Court Booking Application |
| Group Name | Never500 |
| Project Reference | PROPOSAL/UTM/2026 (01) |
| Institution | Universiti Teknologi Malaysia |
| Community | Kolej Rahman Putra (KRP) |
| Project Domain | Web and Mobile Application Development |
| Application Type | Cross-platform Booking System |
| Target Users | UTM Students and KRP Administrators |
| Frontend | Flutter |
| Backend | Node.js and Express (payment backend) |
| Database | Supabase (PostgreSQL) |
| Payment Gateway | Billplz (sandbox) |
| Development Period | 2–3 Months |

---

## ⚠️ Problem Statement

The current Google Form-based booking system presents several challenges for both students and KRP administrators.

### 1. Double-Booking and Slot Conflicts

The existing system uses static dropdown menus that do not synchronize booked time slots immediately.

This allows multiple students to select the same time slot, resulting in booking conflicts and additional administrative work.

### 2. Midnight Booking Bottleneck

Students must wait until 12:01 AM for daily booking slots to become available.

This creates unnecessary inconvenience and causes high traffic during the booking opening period.

### 3. Lack of Student Authentication

The existing form relies on manually entered student information, such as matric numbers and email addresses.

This creates risks of inaccurate information, dummy submissions and unauthorized reservations.

### 4. Manual Payment Verification

Students currently upload payment receipt screenshots after making payments through DuitNow QR.

Administrators must manually compare these receipts against payment records, increasing processing time and the possibility of human error.

### 5. Delayed Booking Confirmations

Students depend on booking confirmation emails, which may occasionally be delayed or fail to arrive.

This creates uncertainty about whether their reservations have been successfully confirmed.

### 6. Repetitive Booking Submissions

Students who want to reserve multiple facilities or consecutive time slots must submit separate forms and make multiple payments.

This makes the overall booking process unnecessarily complicated.

---

## 🎯 Project Objectives

The project aims to:

1. Explore and apply modern software development technologies, including Flutter, Node.js and relational databases, to develop an integrated sports facility booking application.

2. Develop a real-time booking system with database management, API integration and concurrency control to prevent overlapping reservations.

3. Implement secure authentication and role-based access control (RBAC) to verify eligible UTM students and manage student and administrator permissions.

4. Automate booking management through digital payment tracking, booking notifications and an administrative dashboard.

5. Utilize AI-assisted development tools responsibly for technical learning, implementation, debugging and software testing.

6. Conduct system testing and gather stakeholder feedback to evaluate application functionality, usability, security and alignment with KRP community requirements.

---

## 💡 Proposed Solution

The proposed application will provide a centralized platform to improve the sports facility reservation process at KRP.

### For Students

- Secure login using eligible UTM student credentials, subject to available authentication integration.
- Browse available sports facilities.
- View real-time court availability.
- Select preferred dates and time slots.
- Reserve multiple facilities or time slots in one transaction.
- Complete online payments.
- Receive automated booking confirmations.
- View booking history and reservation status.
- Manage cancellations according to booking policies.

### For KRP Administrators

- Access a centralized administrative dashboard.
- Manage sports facilities and availability.
- Monitor reservations in real time.
- View booking and payment records.
- Manage cancellations and refund requests.
- Receive notifications for successful reservations.
- Generate booking summaries and reports.

---

## ✨ Key Features

### Student Module

| Feature | Description |
|---|---|
| Student Authentication | Verify eligible UTM students and provide secure login |
| Home Page | Display sports categories and featured facilities |
| Facility Listing | Browse available sports facilities |
| Facility Details | View location, description, pricing and images |
| Real-Time Availability | Display updated booking slots |
| Multi-Facility Booking | Select multiple facilities or time slots in one transaction |
| Booking Cart | Review selected facilities before payment |
| Online Payment | Complete payments through an integrated payment gateway |
| Booking Confirmation | Automatically confirm successful reservations |
| Booking History | View previous and upcoming bookings |
| Cancellation | Submit cancellation requests according to booking policies |
| User Profile | Manage personal account information |

### Administrator Module

| Feature | Description |
|---|---|
| Admin Authentication | Secure administrator access |
| Dashboard | View booking and facility summaries |
| Facility Management | Add, edit and remove facility information |
| Availability Management | Manage available dates and time slots |
| Booking Management | Monitor and manage reservations |
| Payment Management | View and verify payment transactions |
| Cancellation Management | Handle cancellation and refund requests |
| Notification Management | Receive booking-related updates |
| Reports | Review booking and payment summaries |

---

## 🏟️ Supported Sports Facilities

The initial project scope is based on the sports facilities identified during our community engagement at KRP.

| Facility | Category |
|---|---|
| Badminton Courts | Racket Sports |
| Ping Pong Tables | Table Tennis |
| Snooker | Indoor Sports |
| Darts | Indoor Games |
| Gym Facilities | Fitness |

Facility availability, operating hours, pricing and booking rules will be configured according to KRP administrative requirements.

---

## 👥 Target Users

### 1. UTM Students

The primary users of the application.

Students can:

- Access the system using eligible student credentials.
- Browse and select sports facilities.
- Check available booking slots.
- Reserve one or multiple facilities.
- Make online payments.
- Receive booking confirmations.
- Manage their reservations.

### 2. KRP Administrators

Administrators are responsible for managing the sports facility booking system.

They can:

- Manage facility information.
- Configure booking availability.
- Monitor student reservations.
- Track payment transactions.
- Handle cancellations and refunds.
- Access booking records and reports.

---

## 🛠️ Technology Stack

The following technologies are used to develop the system.

### Frontend — Flutter

Flutter is used to develop the mobile and web interfaces from a shared codebase (`krp_play/lib`).

Responsibilities:

- Responsive user interface development.
- Application navigation.
- Student and administrator interfaces.
- Booking calendar and time-slot selection.
- API communication.

Website: https://flutter.dev/

### Backend — Node.js and Express

A small Node.js and Express server (`krp_play/backend`) handles everything that needs secret keys, so the Flutter app never sees them.

Responsibilities:

- Create Billplz bills from the booking amount stored in the database.
- Verify signed Billplz payment callbacks.
- Confirm paid bookings.
- Run a background job that expires unpaid holds and handles missed or late payments.

Websites:

- https://nodejs.org/
- https://expressjs.com/

### Database — Supabase (PostgreSQL)

Supabase provides the PostgreSQL database and user authentication.

Responsibilities:

- Store student and administrator profiles.
- Manage sports facility information and time slots.
- Store bookings, booking items, payments and refunds.
- Enforce Row Level Security so students only see their own records.
- Calculate prices and reserve slots atomically (`reserve_cart`) to prevent double-booking.

Websites:

- https://supabase.com/
- https://www.postgresql.org/

### Payment Gateway — Billplz

Billplz is used for online payment (FPX). Development and testing use the Billplz sandbox, which does not take real money.

Website: https://www.billplz.com/

### Version Control — Git and GitHub

Git and GitHub support collaborative development, version tracking, branch management and code review.

Website: https://github.com/

---

## 🏗️ System Architecture

The system follows a client-server architecture. The full reference (schema, API contract and state transitions) is in [docs/architecture.md](docs/architecture.md).

```text
           STUDENTS          ADMINISTRATORS
              |                   |
              +---------+---------+
                        |
                 FLUTTER APP (krp_play/lib)
                 mobile and web
                   |            |
   Supabase Auth,  |            |  HTTPS + user token
   reads, RPCs     |            |  (create payment, status)
                   v            v
     SUPABASE (POSTGRESQL)  <--  PAYMENT BACKEND
     auth, RLS, bookings,        Node.js + Express
     payments, refunds           (krp_play/backend)
                                    |        ^
                     create / read  |        |  signed callback
                     bills          v        |  (via ngrok)
                                 BILLPLZ (sandbox)
```

**Trust rule:** money, price, student category, role and payment success are decided by the database or the backend, never by the app.

### Important System Requirements

**Real-Time Booking Synchronization**

The backend must validate court availability before accepting a reservation.

**Concurrency Control**

Database transactions and appropriate database constraints must prevent two users from successfully reserving overlapping time slots for the same facility.

**Secure Authentication**

The system must verify student eligibility and implement role-based access control.

**Payment Verification**

Payment status must be verified through trusted backend communication with the payment gateway.

**Automated Notifications**

The system should automatically notify relevant users and administrators when important booking events occur.

---

## 🗄️ Database Design

The database is hosted on Supabase. The main tables are listed below; see [docs/architecture.md](docs/architecture.md) for the full ERD.

| Table | Purpose |
|---|---|
| `profiles` | Student and administrator accounts (`role`: `student` / `admin`; `student_category`: `krp` / `non_krp`) |
| `facilities` | Sports facility information and pricing |
| `time_slots` | Bookable sessions for each facility |
| `bookings` | Reservation records |
| `booking_items` | Individual sessions in a booking |
| `payments` | Payment attempts and Billplz references |
| `refunds` / `refund_events` | Refund requests and their history |
| `reports` | Student reports (facility, payment or booking issues) |

### Booking Status

- `pending_payment` (10-minute hold while waiting for payment)
- `confirmed`
- `expired`
- `closed` (session closed by an admin; refund needed)
- `refunded`

### Payment Status

- `pending`
- `paid`
- `simulated_success` (demo mode only)

### SQL Files

Schema changes are SQL files in [database/](database/), run by hand in **Supabase → SQL Editor**:

| Order | File | Purpose |
|---|---|---|
| 1 | `database/atomic_checkout.sql` | All-or-nothing cart reservation (`reserve_cart`) |
| 2 | `database/confirm_payment.sql` | Payment confirmation, expiry and late payments |
| 3 | `database/student_category.sql` | Standard `krp` / `non_krp` student category values |

### Database Security

- Use appropriate primary keys and foreign keys.
- Validate booking dates and time ranges.
- Prevent overlapping active reservations.
- Restrict students to their own booking records.
- Apply administrator permissions to management operations.
- Protect payment credentials and sensitive information.

---

## 🔄 System Workflow

### Student Booking Workflow

```text
START
  |
  v
Student Login
  |
  v
Verify Student Eligibility
  |
  v
Browse Sports Facilities
  |
  v
Select Facility / Facilities
  |
  v
Select Date and Time Slots
  |
  v
Add Selections to Booking Cart
  |
  v
Review Booking Details
  |
  v
Check Real-Time Availability
  |
  v
Create Pending Reservation
  |
  v
Proceed to Online Payment
  |
  v
Payment Gateway Processing
  |
  v
Backend Payment Verification
  |
  +------ Payment Successful?
  |             |
  |          YES / NO
  |             |
  |       +-----+-----+
  |       |           |
  |      YES          NO
  |       |           |
  v       v           v
Confirm   Update     Handle Failed
Booking   Payment    or Expired Booking
  |
  v
Send Confirmation
  |
  v
END
```

### Administrator Workflow

```text
Admin Login
    |
    v
Admin Dashboard
    |
    v
Manage Facilities
    |
    v
Update Availability
    |
    v
Monitor Reservations
    |
    v
Review Payment Records
    |
    v
Manage Cancellations
    |
    v
View Reports
```

---

## 📂 Project Structure

```text
Never500/
│
├── README.md
│
├── database/                   # SQL files run in the Supabase SQL Editor
│   ├── atomic_checkout.sql
│   ├── confirm_payment.sql
│   ├── student_category.sql
│   └── tests/                  # Checkout tests against a disposable PostgreSQL database
│
├── docs/                       # Architecture and test evidence
│   ├── architecture.md
│   ├── atomic-checkout.md
│   ├── cart-checkout-evidence.md
│   └── cart-review-evidence.md
│
└── krp_play/                   # Flutter application
    │
    ├── android/ ios/ web/ windows/ macos/ linux/
    │
    ├── lib/
    │   ├── main.dart
    │   ├── models/             # booking, facility, reservation, student account, ...
    │   ├── screens/            # student screens
    │   │   └── admin/          # admin dashboard, slots, reservations, refunds, reports
    │   ├── services/           # auth_service.dart, booking_service.dart
    │   └── widgets/            # sidebar, top bar, booking history, facility card, ...
    │
    ├── assets/
    │   ├── facilities/
    │   └── images/
    │
    ├── test/                   # Flutter widget tests
    │
    ├── backend/                # Node.js + Express payment backend (Billplz)
    │   ├── app.js
    │   ├── scripts/fake-callback.js
    │   ├── .env.example
    │   └── README.md
    │
    ├── frontend/               # Early React (Vite) UI prototype
    │
    ├── run_web.ps1             # Runs the Flutter web app against the payment backend
    └── pubspec.yaml
```

---

## 🚀 Getting Started

### Prerequisites

Install the following development tools:

- Flutter SDK
- Dart SDK
- Visual Studio Code
- Git
- Google Chrome
- Android Studio (for Android development)
- Node.js and npm (for backend development)

### 1. Clone the Repository

```bash
git clone https://github.com/shelingng/Never500.git
```

### 2. Navigate to the Flutter Project

```bash
cd krp_play
```

### 3. Check Flutter Installation

```bash
flutter doctor
```

### 4. Install Flutter Dependencies

```bash
flutter pub get
```

### 5. Run the Flutter Application

On Windows, use the helper script. It runs the app in Chrome and points checkout at the payment backend (default `http://localhost:3000`):

```powershell
.\run_web.ps1
```

Or run Flutter directly:

```bash
flutter run -d chrome
```

### 6. Run the Tests

```bash
flutter test
```

Database checkout tests are in [database/tests/](database/tests/). They need an **empty, disposable** PostgreSQL database; never point them at the hosted Supabase project.

### 7. Build the Web Application

```bash
flutter build web
```

The generated web files will be located in:

```text
build/web/
```

### Database Setup

Run the SQL files in [database/](database/) in the Supabase SQL Editor, in the order listed in [SQL Files](#sql-files).

### Backend Setup

The payment backend needs a Billplz sandbox account, an ngrok domain and a `.env` file. Follow [krp_play/backend/README.md](krp_play/backend/README.md).

---

## 🗓️ Development Roadmap

The project is planned for completion within approximately 2–3 months.

| Phase | Development Activities | Status |
|---|---|---|
| 1 | Requirement analysis and system planning | Completed |
| 2 | UI/UX design and responsive Flutter development | In Progress |
| 3 | Student authentication and role management | In Progress |
| 4 | Backend API and database implementation | In Progress |
| 5 | Facility and real-time booking management | In Progress |
| 6 | Multi-facility booking and cart functionality | In Progress |
| 7 | Online payment integration | In Progress |
| 8 | Admin dashboard and notifications | In Progress |
| 9 | System testing and stakeholder feedback | In Progress |
| 10 | Deployment and final documentation | Planned |

---

## 👨‍💻 Team Members and Roles

**Group Name: Never500**

| No. | Team Member | Role | Main Responsibility |
|---|---|---|---|
| 1 | Looi Yu Xiang | Project Manager | Project planning, timeline coordination, documentation and stakeholder communication |
| 2 | Tan Jia Yie | Architecture Designer | System architecture, wireframes, interactive prototypes and overall interface design |
| 3 | Ng She Ling | Frontend Developer | Flutter UI implementation, responsive interfaces, calendar and notifications |
| 4 | Chan Siew Ching | Backend Developer | Database, APIs, booking logic, authentication and payment integration |
| 5 | Mohamad Adrian Syahirin Bin Mohd Faizal | Quality Assurance Tester | Test cases, bug identification, defect reporting and system testing |

---

## 🤝 GitHub Collaboration

The project uses Git and GitHub to support collaborative development.

### Branch Naming Convention

Work is tracked in Jira. Name each branch after its Jira issue:

```text
SCRUM-<issue-number>-<short-description>
```

Examples:

```text
SCRUM-38-student-category
SCRUM-48-booking-history
SCRUM-80-payment-outcomes
```

Start commit messages with the same Jira key, for example `SCRUM-48: Load booking history`.

### Development Workflow

1. Pull the latest changes from the main branch.
2. Create a separate feature branch.
3. Implement the assigned feature.
4. Test the changes locally.
5. Commit and push the changes.
6. Create a Pull Request.
7. Review and merge approved changes into the main branch.

### Example Commands

```bash
git pull origin main

git switch -c SCRUM-<issue-number>-<short-description>

git add .

git commit -m "SCRUM-<issue-number>: Describe the change"

git push -u origin SCRUM-<issue-number>-<short-description>
```

Team members should avoid committing directly to the main branch without agreement.

Never commit passwords, private API keys, payment secrets or environment files to GitHub.

---

## 📊 Project Status

**Current Stage: Feature Development and Testing**

Completed:

- Project proposal and requirement analysis.
- Community engagement with KRP JKP representatives.
- Identification of existing booking system challenges.
- Flutter, Supabase and payment backend setup.
- Architecture, schema and state transition reference ([docs/architecture.md](docs/architecture.md)).

In Progress:

- Student sign-in and KRP / Non-KRP student categories.
- Facility listing and slot availability.
- All-or-nothing cart checkout ([docs/atomic-checkout.md](docs/atomic-checkout.md)).
- Billplz sandbox payment, callback verification, expiry and late payments.
- Booking history.
- Administrator dashboard, slot management, reservations, refunds and reports.
- Automated and manual testing.

Planned:

- Stakeholder feedback sessions.
- Deployment and final documentation.

---

## 🌱 Project Vision

The application aims to transform the existing KRP sports facility booking experience through a more accessible, secure and efficient digital platform.

By addressing real challenges identified through community engagement, the application seeks to reduce administrative workload, improve booking transparency, eliminate scheduling conflicts and provide students with a more convenient way to access sports facilities.

**UTM KRP Sport Court Booking Application**

*Book Smarter. Play Better. Stay Active.*

---

<p align="center">
  <strong>Developed by Team Never500</strong><br>
  Universiti Teknologi Malaysia (UTM)<br>
  2026
</p>