# Crop Doctor - Project Documentation

This documentation covers the backend API endpoints and the mobile app features for the **Crop Doctor** application.

---

## 1. Mobile App Features

The mobile application is built using Flutter and includes a comprehensive set of screens and features to help users manage and diagnose crop diseases.

### Authentication & Onboarding
- **Welcome Screen:** Initial landing screen introducing the app.
- **Login / Register:** Secure user authentication allowing users to create accounts or log in.

### Core Scanning & Diagnosis
- **Camera Screen:** Capture images of crops directly from the device to scan for potential diseases.
- **Result Screen:** Displays the outcome of the scan, showing the detected disease, confidence level, and recommended actions.
- **History Screen:** View a log of previous scans and their results.

### Knowledge & Community
- **Solutions Library:** A catalog containing information on various diseases, crops, and their corresponding solutions/treatments.
- **Forum:** 
  - Community discussions where users can ask questions and experts or other users can answer.
  - Features to view all questions, question details, and manage "My Questions".
  - Ability to like answers and engage with the community.

### User Profiles & Subscriptions
- **Profile Management:** View and edit personal user details.
- **Subscriptions:**
  - Browse available subscription plans for premium features.
  - View subscription details and track payment history.

### Admin & Expert Capabilities
- **Admin Panel:** Special features for administrators to manage users, plans, and monitor the system.
- **Expert Panel:** Interface for domain experts to review questions, provide verified answers, and assist users.

---

## 2. Backend API Endpoints

The backend is powered by Django Rest Framework, providing the following endpoints:

### User Management (`/api/users/`)
- `POST /api/users/register/` - Register a new user account.
- `POST /api/users/login/` - Authenticate a user and obtain tokens.
- `GET, PUT /api/users/profile/` - Retrieve or update the current user's profile.
- `POST /api/users/logout/` - Invalidate the user session/tokens.
- `GET /api/users/stats/` - Get statistics related to the user's activity.
- `GET, POST, PUT, DELETE /api/users/admin/users/` - Admin endpoints for full user management.
- `GET, POST, PUT, DELETE /api/users/expert/users/` - Admin/Expert endpoints for managing expert users.

### Scan & Catalog (`/api/`)
- `POST /api/scan/` - Submit an image for crop disease analysis.
- `GET /api/scan/history/` - Retrieve the scan history for the authenticated user.
- `GET /api/catalog/diseases/` - Get a list of all cataloged diseases.
- `GET /api/catalog/crops/` - Get a list of all cataloged crops.
- `GET /api/catalog/solutions/` - Get a list of solutions and treatments for diseases.

### Subscriptions & Payments (`/api/`)
- **Plans:**
  - `GET /api/get-plans/` - List all available subscription plans for users.
  - `GET /api/admin/get-plans/` - Admin view for subscription plans.
  - `POST /api/admin/create-plan/` - Admin endpoint to create a new plan.
  - `PUT /api/admin/update-plan/<id>/` - Admin endpoint to modify a plan.
  - `DELETE /api/admin/delete-plan/<id>/` - Admin endpoint to remove a plan.
- **User Subscriptions:**
  - `GET /api/subscriptions/my/` - View current user's active subscriptions.
  - `GET /api/subscriptions/my/<id>/` - View details of a specific user subscription.
  - `GET /api/admin/get-subscriptions/` - Admin view of all user subscriptions.
  - `GET, PUT, DELETE /api/admin/get-subscription/<id>/` - Admin endpoints to manage a specific user's subscription.
- **Payments:**
  - `POST /api/subscriptions/create-subscription-payment/` - Initialize a payment process for a plan.
  - `GET, POST /api/subscriptions/payment-success/` - Payment success callback handler.
  - `GET, POST /api/subscriptions/payment-fail/` - Payment failure callback handler.
  - `GET, POST /api/subscriptions/payment-cancel/` - Payment cancellation callback handler.
  - `POST /api/subscriptions/payment-ipn/` - Instant Payment Notification endpoint.

### Forums & Community (`/api/`)
- **Questions:**
  - `GET /api/questions/all/` - Get a list of all community questions.
  - `GET /api/questions/get-all-questions/` - Get community questions (with potential filtering/pagination).
  - `GET /api/question/<id>/` - Retrieve a specific question's details.
  - `POST /api/question/create-question/` - Post a new question to the forum.
  - `PUT /api/question/<id>/update-question/` - Update an existing question.
  - `DELETE /api/question/<id>/delete-question/` - Delete a question.
- **Answers:**
  - `GET /api/answers/get-all-answers/` - Get answers for questions.
  - `GET /api/answer/<id>/` - Retrieve a specific answer.
  - `POST /api/answer/create-answer/` - Post a new answer to a question.
  - `PUT /api/answer/<id>/update-answer/` - Update an existing answer.
  - `DELETE /api/answer/<id>/delete-answer/` - Delete an answer.
  - `POST /api/answer/<id>/like/` - Toggle the like status on an answer.
