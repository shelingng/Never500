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
| Backend | Node.js and Express (proposed) |
| Database | PostgreSQL (proposed) |
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
| Draft | Indoor Games |
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

The following technologies are proposed for the development of the system.

### Frontend — Flutter

Flutter will be used to develop the mobile and web interfaces from a shared codebase.

Responsibilities:

- Responsive user interface development.
- Application navigation.
- Student and administrator interfaces.
- Booking calendar and time-slot selection.
- API communication.

Website: https://flutter.dev/

### Backend — Node.js and Express

Node.js with Express is proposed for backend API development.

Responsibilities:

- Handle application requests.
- Process booking operations.
- Implement authentication and authorization.
- Validate booking availability.
- Prevent overlapping reservations.
- Integrate payment gateway APIs.
- Manage booking and payment notifications.

Websites:

- https://nodejs.org/
- https://expressjs.com/

### Database — PostgreSQL

PostgreSQL is proposed as the relational database management system.

Responsibilities:

- Store student and administrator records.
- Manage sports facility information.
- Store booking details.
- Track payment transactions.
- Maintain data relationships and integrity.

Website: https://www.postgresql.org/

### Payment Gateway

A suitable online payment gateway will be integrated to support digital payment processing.

Potential options:

- Billplz: https://www.billplz.com/
- ToyyibPay: https://toyyibpay.com/

The final provider will depend on API availability, testing support and project requirements.

### Version Control — Git and GitHub

Git and GitHub will support collaborative development, version tracking, branch management and code review.

Website: https://github.com/

---

## 🏗️ System Architecture

The proposed system follows a client-server architecture.

```text
                UTM KRP COMMUNITY
                        |
              +---------+---------+
              |                   |
           STUDENTS          ADMINISTRATORS
              |                   |
              +---------+---------+
                        |
                 FLUTTER FRONTEND
               +--------+--------+
               |                 |
          MOBILE APP         WEB APP
               |                 |
               +--------+--------+
                        |
                    REST API
                        |
                NODE.JS + EXPRESS
                        |
          +-------------+-------------+
          |             |             |
    AUTHENTICATION   BOOKING       PAYMENT
                     MANAGEMENT    PROCESSING
          |             |             |
          +-------------+-------------+
                        |
                  POSTGRESQL
                    DATABASE
                        |
             +----------+----------+
             |          |          |
           USERS      COURTS     BOOKINGS
                                   |
                                PAYMENTS
                        |
              EXTERNAL INTEGRATIONS
                        |
              +---------+---------+
              |                   |
         PAYMENT GATEWAY     EMAIL SERVICE
```

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

The following tables are proposed for the initial database design.

| Table | Purpose |
|---|---|
| `users` | Store student and administrator accounts |
| `facilities` | Store sports facility information |
| `time_slots` | Manage facility booking schedules |
| `bookings` | Store reservation records |
| `booking_items` | Store individual facilities or time slots in a booking |
| `payments` | Store payment transaction details |
| `notifications` | Store booking-related notification records |

### Proposed Booking Status

- `pending_payment`
- `confirmed`
- `cancelled`
- `expired`

### Proposed Payment Status

- `pending`
- `paid`
- `failed`
- `refunded`

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

The following is the proposed Flutter project structure.

```text
Never500/
│
├── README.md
│
└── krp_play/
    │
    ├── android/
    ├── ios/
    ├── web/
    ├── windows/
    ├── macos/
    │
    ├── lib/
    │   ├── main.dart
    │   │
    │   ├── models/
    │   │   ├── user_model.dart
    │   │   ├── facility_model.dart
    │   │   ├── booking_model.dart
    │   │   └── payment_model.dart
    │   │
    │   ├── screens/
    │   │   ├── auth/
    │   │   ├── home/
    │   │   ├── facilities/
    │   │   ├── booking/
    │   │   ├── cart/
    │   │   ├── payment/
    │   │   ├── profile/
    │   │   └── admin/
    │   │
    │   ├── widgets/
    │   │
    │   ├── services/
    │   │   ├── api_service.dart
    │   │   ├── auth_service.dart
    │   │   ├── facility_service.dart
    │   │   ├── booking_service.dart
    │   │   └── payment_service.dart
    │   │
    │   └── utils/
    │
    ├── assets/
    │   ├── images/
    │   └── icons/
    │
    └── pubspec.yaml
```

The backend will be maintained separately when implemented.

```text
backend/
│
├── src/
│   ├── config/
│   ├── controllers/
│   ├── middleware/
│   ├── models/
│   ├── routes/
│   ├── services/
│   └── app.js
│
├── database/
│   └── migrations/
│
├── .env.example
├── package.json
└── server.js
```

*The structure is a proposed organization and will be updated as the project develops.*

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

```bash
flutter run -d chrome
```

### 6. Build the Web Application

```bash
flutter build web
```

The generated web files will be located in:

```text
build/web/
```

### Backend Setup

Backend installation instructions will be added when the Node.js backend is established.

---

## 🗓️ Development Roadmap

The project is planned for completion within approximately 2–3 months.

| Phase | Development Activities | Status |
|---|---|---|
| 1 | Requirement analysis and system planning | In Progress |
| 2 | UI/UX design and responsive Flutter development | Planned |
| 3 | Student authentication and role management | Planned |
| 4 | Backend API and database implementation | Planned |
| 5 | Facility and real-time booking management | Planned |
| 6 | Multi-facility booking and cart functionality | Planned |
| 7 | Online payment integration | Planned |
| 8 | Admin dashboard and notifications | Planned |
| 9 | System testing and stakeholder feedback | Planned |
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

```text
feature/<developer-name>/<feature-name>
```

Examples:

```text
feature/tanjiayie/flutter-setup
feature/member1/login-page
feature/member2/facility-listing
feature/member3/booking-system
```

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

git switch -c feature/your-name/feature-name

git add .

git commit -m "Add feature description"

git push -u origin feature/your-name/feature-name
```

Team members should avoid committing directly to the main branch without agreement.

Never commit passwords, private API keys, payment secrets or environment files to GitHub.

---

## 📊 Project Status

**Current Stage: Initial Setup and Requirement Analysis**

Completed:

- Project proposal and requirement analysis.
- Community engagement with KRP JKP representatives.
- Identification of existing booking system challenges.
- Initial Flutter development environment setup.
- Initial Flutter application testing in Chrome.
- GitHub repository and feature branch setup.

In Progress:

- System architecture planning.
- UI/UX design.
- Technology selection.
- Frontend development.

Planned:

- Student authentication.
- Real-time availability.
- Booking and cart management.
- Backend and database integration.
- Online payment integration.
- Administrator dashboard.
- System testing and deployment.

---

## 🌱 Project Vision

CourtMate aims to transform the existing KRP sports facility booking experience through a more accessible, secure and efficient digital platform.

By addressing real challenges identified through community engagement, the application seeks to reduce administrative workload, improve booking transparency, eliminate scheduling conflicts and provide students with a more convenient way to access sports facilities.

**UTM KRP Sport Court Booking Application**

*Book Smarter. Play Better. Stay Active.*

---

<p align="center">
  **Developed by Team Never500**  
  Universiti Teknologi Malaysia (UTM)  
  2026
</p>