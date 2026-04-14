# SwapSpace Test Cases

> Notes: "Actual Result" and "Status" are intentionally left blank for execution-time completion.

## 1) Authentication
| Test Case ID | Module | Test Scenario | Test Type | Test Level | Preconditions | Test Steps | Expected Result | Actual Result | Status | Priority |
|---|---|---|---|---|---|---|---|---|---|---|
| AUTH-001 | Authentication | Sign in with valid Google account | Functional | System | User has a valid Google account; internet available | 1) Open app 2) Accept consent 3) Tap "Sign in" 4) Complete Google auth | User is signed in; home screen loads |  |  | High |
| AUTH-002 | Authentication | Decline privacy consent | Functional | System | App freshly installed; no consent stored | 1) Open app 2) Tap "Decline" | Sign-in is blocked; user remains on login screen |  |  | High |
| AUTH-003 | Authentication | Sign-in cancelled by user | Functional | System | Consent accepted | 1) Tap "Sign in" 2) Close Google auth popup | App shows cancellation message; no login |  |  | Medium |
| AUTH-004 | Authentication | Re-authentication required for sensitive action | Security | System | User signed in | 1) Trigger account deletion 2) Follow re-auth flow | User is prompted to re-auth; flow completes |  |  | High |
| AUTH-005 | Authentication | Logout | Functional | System | User signed in | 1) Open profile 2) Tap logout | Session ends; app returns to login screen |  |  | High |

## 2) Session Management
| Test Case ID | Module | Test Scenario | Test Type | Test Level | Preconditions | Test Steps | Expected Result | Actual Result | Status | Priority |
|---|---|---|---|---|---|---|---|---|---|---|
| SESS-001 | Session Management | Create a session with valid inputs | Functional | System | User signed in | 1) Open Create 2) Fill fields 3) Submit | Session is created and appears in home list |  |  | High |
| SESS-002 | Session Management | Validation on required fields | Functional | System | User signed in | 1) Open Create 2) Leave title empty 3) Submit | Form shows validation errors; no write |  |  | High |
| SESS-003 | Session Management | Edit session by creator | Functional | System | User is creator of a session | 1) Open session detail 2) Tap Edit 3) Save | Session updates; list reflects changes |  |  | High |
| SESS-004 | Session Management | Cancel session by creator | Functional | System | User is creator | 1) Open session detail 2) Cancel | Session status becomes cancelled |  |  | High |
| SESS-005 | Session Management | Pagination load-more in home feed | Performance | System | Sessions exceed page size | 1) Scroll near end of list | Next page loads without duplicates |  |  | Medium |
| SESS-006 | Session Management | Filter sessions by activity | Functional | System | Sessions exist in multiple categories | 1) Select filter tab | List shows matching sessions only |  |  | Medium |

## 3) Join Requests
| Test Case ID | Module | Test Scenario | Test Type | Test Level | Preconditions | Test Steps | Expected Result | Actual Result | Status | Priority |
|---|---|---|---|---|---|---|---|---|---|---|
| JR-001 | Join Requests | Send join request | Functional | System | User signed in; session available | 1) Open session 2) Tap "Request to Join" | Request created; notification sent to creator |  |  | High |
| JR-002 | Join Requests | Accept join request | Functional | System | Creator has pending request | 1) Open requests tab 2) Accept | Status becomes accepted; session updated |  |  | High |
| JR-003 | Join Requests | Reject join request | Functional | System | Creator has pending request | 1) Open requests tab 2) Reject | Status becomes rejected; requester notified |  |  | High |
| JR-004 | Join Requests | Cancel outgoing request | Functional | System | Requester has pending request | 1) Open outgoing requests 2) Cancel | Request is cancelled; list updates |  |  | Medium |
| JR-005 | Join Requests | Leave session request | Functional | System | User joined session | 1) Open session detail 2) Request to leave | Leave request created; creator notified |  |  | High |

## 4) Notifications
| Test Case ID | Module | Test Scenario | Test Type | Test Level | Preconditions | Test Steps | Expected Result | Actual Result | Status | Priority |
|---|---|---|---|---|---|---|---|---|---|---|
| NOTIF-001 | Notifications | Receive join request notification | Functional | System | Creator receives new request | 1) Open notifications tab | New notification visible |  |  | Medium |
| NOTIF-002 | Notifications | Mark notification as read | Functional | System | User has unread notification | 1) Tap notification card | Notification marked as read |  |  | Medium |
| NOTIF-003 | Notifications | Pagination load-more | Performance | System | Notifications exceed page size | 1) Scroll near end | Next page loads; ordering preserved |  |  | Low |

## 5) Feedback and Ratings
| Test Case ID | Module | Test Scenario | Test Type | Test Level | Preconditions | Test Steps | Expected Result | Actual Result | Status | Priority |
|---|---|---|---|---|---|---|---|---|---|---|
| FB-001 | Feedback | Submit feedback after session completed | Functional | System | User participated in completed session | 1) Open session detail 2) Tap "Give Feedback" 3) Submit | Feedback created; rating saved |  |  | High |
| FB-002 | Feedback | Rating bounds enforced | Functional | System | Feedback form open | 1) Try invalid rating (e.g., 0) | Validation prevents submission |  |  | High |
| FB-003 | Feedback | Prevent duplicate feedback | Functional | System | Feedback already submitted | 1) Open feedback screen again | App blocks or hides submission |  |  | Medium |

## 6) User Profiles
| Test Case ID | Module | Test Scenario | Test Type | Test Level | Preconditions | Test Steps | Expected Result | Actual Result | Status | Priority |
|---|---|---|---|---|---|---|---|---|---|---|
| PROF-001 | User Profiles | View own profile | Functional | System | User signed in | 1) Open profile tab | Profile data renders correctly |  |  | High |
| PROF-002 | User Profiles | View another user profile | Functional | System | Public profile exists | 1) Tap user avatar/name | Public profile loads |  |  | Medium |
| PROF-003 | User Profiles | Load created sessions tab | Functional | System | User has created sessions | 1) Open profile 2) Select Created | Sessions list loads with pagination |  |  | Medium |
| PROF-004 | User Profiles | Load joined sessions tab | Functional | System | User has joined sessions | 1) Open profile 2) Select Joined | Sessions list loads with pagination |  |  | Medium |

## 7) Privacy and Security
| Test Case ID | Module | Test Scenario | Test Type | Test Level | Preconditions | Test Steps | Expected Result | Actual Result | Status | Priority |
|---|---|---|---|---|---|---|---|---|---|---|
| PRIV-001 | Privacy & Security | Export user data | Functional | System | User signed in | 1) Profile > Privacy Controls 2) Export | JSON export is shown |  |  | Medium |
| PRIV-002 | Privacy & Security | Delete account data | Security | System | User signed in | 1) Profile > Privacy Controls 2) Delete | Account data removed; sign-out occurs |  |  | High |
| PRIV-003 | Privacy & Security | Firestore rules block cross-user reads | Security | Integration | Two test users | 1) User A attempts read of User B doc | Access denied |  |  | High |
| PRIV-004 | Privacy & Security | Firestore rules block unauthorized writes | Security | Integration | Two test users | 1) User A attempts update User B doc | Write denied |  |  | High |

## 8) Performance and Reliability
| Test Case ID | Module | Test Scenario | Test Type | Test Level | Preconditions | Test Steps | Expected Result | Actual Result | Status | Priority |
|---|---|---|---|---|---|---|---|---|---|---|
| PERF-001 | Performance & Reliability | App cold-start time | Performance | System | Release build available | 1) Launch app cold | Startup completes within target threshold |  |  | Medium |
| PERF-002 | Performance & Reliability | Pagination performance | Performance | System | Dataset > 100 sessions | 1) Scroll to load multiple pages | No jank; requests stay under target latency |  |  | Medium |
| PERF-003 | Performance & Reliability | Offline handling | Reliability | System | Device offline | 1) Open app 2) Navigate to lists | Friendly error or cached data shown |  |  | High |
| PERF-004 | Performance & Reliability | Network recovery | Reliability | System | Device returns online | 1) Reconnect 2) Refresh | Data reloads successfully |  |  | Medium |
| PERF-005 | Performance & Reliability | Crash reporting enabled | Reliability | System | Crashlytics configured | 1) Trigger test crash | Crash is recorded in Firebase |  |  | Low |

## 9) Acceptance Criteria and Quality Metrics
- All High-priority test cases must pass.
- At least 95% of Medium-priority test cases must pass.
- No Critical or High-severity defects remain unresolved.
- Application crash rate must be below 1%.
- App startup time should be under 3 seconds.
- Firestore queries must follow pagination and indexing best practices.
- All automated tests must pass in the CI/CD pipeline.
- No critical security vulnerabilities are detected.

## 10) Requirements Traceability Matrix (RTM)
| Requirement ID | Feature | Test Case IDs |
|---|---|---|
| FR-01 | Authentication | AUTH-001 to AUTH-005 |
| FR-02 | Session Management | SESS-001 to SESS-006 |
| FR-03 | Join Requests | JR-001 to JR-005 |
| FR-04 | Notifications | NOTIF-001 to NOTIF-003 |
| FR-05 | Feedback System | FB-001 to FB-003 |
| FR-06 | User Profiles | PROF-001 to PROF-004 |
| FR-07 | Privacy and Security | PRIV-001 to PRIV-004 |
| NFR-01 | Performance | PERF-001 to PERF-002 |
| NFR-02 | Reliability | PERF-003 to PERF-004 |
| NFR-03 | Monitoring and Stability | PERF-005 |

## 11) Test Automation Strategy
| Category | Approach |
|---|---|
| Unit Tests | Automated using `flutter test` |
| Widget Tests | Automated using Flutter testing framework |
| Integration Tests | Automated using Flutter Integration Test |
| Firestore Rules Testing | Automated using Firebase Emulator Suite |
| Performance Testing | Semi-automated using Firebase Performance Monitoring |
| Security Testing | Manual and emulator-based validation |
| User Acceptance Testing | Manual testing by stakeholders |
