# Field Service Management (FSM) Mobile Application

A premium, offline-first mobile application built with **Flutter** using **Clean Architecture** principles. Designed for field technicians to manage service requests, track job progress, record reports with GPS and image evidence, and maintain history logs.

---

## 1. Project Architecture

The application is structured using **Feature-First Clean Architecture**. This model isolates business logic from UI frameworks and databases, ensuring high testability, scalable development, and robust maintenance.

```
lib/
├── core/                           # Shared system-wide modules
│   ├── constants/                  # Constants (colors, configurations)
│   ├── error/                      # Failure & Exception definitions
│   ├── network/                    # Network connectivity checking
│   ├── theme/                      # Styling definitions
│   └── usecases/                   # UseCase base interfaces
│
└── features/                       # Modular business features
    ├── auth/                       # Authentication & Session Management
    ├── dashboard/                  # Stats summaries and job categorization
    ├── jobs/                       # Job Management (fetch list, accept/reject, updates)
    ├── notifications/              # Alerts and notifications inbox
    └── service_reports/            # Form validations, sync queue, GPS/evidence capture
```

### The Three Core Layers (In Each Feature)
1. **Domain Layer**: The heart of the module. Written in pure Dart with zero external package dependencies. Defines **Entities** (business objects), **Usecases** (actions technicians can perform), and **Repository contracts** (interfaces).
2. **Data Layer**: Implements repository interfaces. Manages JSON mapping via **Models** and data retrieval via **Data Sources** (REST API/Firestore remote sources and Hive local cache sources).
3. **Presentation Layer**: Handles UI layouts and user interactions. Governed by **BLoC State Management** (`flutter_bloc`), separating widgets from state business flow.

---

## 2. Key Features

### 🔐 1. Authentication & Session Management
* **Credentials**: Supports registration and login via email & password.
* **Profiles**: Captures Full Name, Contact Number, and Role (Field Technician or Supervisor).
* **Caching**: Authenticated user sessions are stored locally in Hive. Upon restart, the app automatically logs the user in without requiring internet.

### 📊 2. Service Dashboard & Statistics
* **Stats Cards**: Displays aggregations of Total, Pending, Active, and Completed jobs.
* **Filter Tabs**: Neat Material 3 tab interface to filter jobs into "All", "Pending", "Active", and "Completed" categories.
* **Pull-to-Refresh**: Easily reload tasks.

### 🛠 3. Job Management
* **Status Lifespan**: Jobs transition dynamically through `pending` $\rightarrow$ `accepted` $\rightarrow$ `in_progress` $\rightarrow$ `completed`.
* **Actions**: Technicians can accept or reject pending jobs, start accepted jobs, and initiate report creation.
* **Details**: View customer name, contact phone, adresse coordinates, and service scheduled dates.

### 📝 4. Service Report Module (Offline-First)
* **Form Validations**: Validates service findings and actions taken inputs using standard controller validators.
* **Evidence Gathering**:
  * **GPS Simulation**: Instantly captures mock coordinates (`31.9539° N, 35.9106° E` Amman, Jordan) and displays them in a chip.
  * **Camera Photo Simulation**: Attaches mock photo metadata to the service record.
* **Offline Sync Queue**: If the user is offline, report submission succeeds locally, saves in a Hive sync queue, and displays a pending sync counter on the dashboard.

### 🔄 5. Connectivity Banner & Auto-Sync
* **Visual Banner**: A red warning banner (**"Offline Mode - Local cache active"**) appears at the top of the dashboard whenever the device loses connection.
* **Auto-Sync**: Regaining internet connection automatically triggers the background sync processor, uploading all queued service reports to Firestore, completing their corresponding jobs, and showing a success toast.

### 📜 6. Service History Log
* Access previous completed report details (Findings, Actions, Date Completed, Report ID) stored locally in the Hive database.

### 🔔 7. Notifications Center
* Local notifications inbox seeded with initial alerts (New jobs, reminders, synchronization completes).

---

## 3. Technology Stack & Key Dependencies

| Dependency | Purpose |
| :--- | :--- |
| **flutter_bloc** | State Management (Event-to-State segregation) |
| **hive / hive_flutter** | Offline caching and Sync Queue (NoSQL database) |
| **firebase_auth** | Remote Authentication |
| **cloud_firestore** | Remote Real-time Database |
| **internet_connection_checker** | Online/Offline network status checks |
| **get_it** | Service Locator / Dependency Injection |
| **fpdart** | Functional Programming helpers (`Either` for failures/success) |
| **formz** | Simplified form state validation |
| **mask_text_input_formatter** | Phone number masking (e.g. `+962-##-###-####`) |

---

## 4. Getting Started & Installation

### Prerequisites
* Flutter SDK (Version `3.10.4` or higher)
* Dart SDK (Version `3.0.0` or higher)

### Setup Instructions
1. **Clone & Navigate**:
   ```bash
   cd field_service_management_app
   ```
2. **Resolve Packages**:
   ```bash
   flutter pub get
   ```
3. **Verify Codebase**:
   Ensure there are no compilation errors:
   ```bash
   flutter analyze
   ```
4. **Run Unit Tests**:
   Execute the Clean Architecture test suite testing use cases:
   ```bash
   flutter test
   ```
5. **Run the Application**:
   Launch on emulator or physical device:
   ```bash
   flutter run
   ```

---

## 5. Offline-First Testing Checklist

1. **Sign Up**: Register a new user using the registration page.
2. **Load Jobs**: Confirm that default jobs load on the Dashboard (they are seeded to Firestore automatically if collections are empty).
3. **Go Offline**: Turn off Wi-Fi/Cellular data.
4. **Accept & Start Job**: Tap a pending job. Accept it, then tap "Start Work". Note that the status updates instantly using local caching.
5. **Submit Report**: Click **Complete Job & Create Report**. Fill in the fields, click "Capture GPS", click "Add Evidence Image", and submit.
6. **Verify Sync Banner**: Note that the dashboard displays `1 Service Report(s) pending sync` and the status remains safe in local storage.
7. **Go Online**: Restore connection. The app automatically detects connection status, pushes the report to Firestore, and clears the sync queue.
