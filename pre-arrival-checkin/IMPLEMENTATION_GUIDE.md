# Implementation Guide: Further Details & Accessibility Form

## Overview
This guide explains how to integrate the "Further Details" page and "Accessibility & Special Requests" form into your pre-arrival check-in flow.

## Files Created

1. **`further-details.html`** - Main form page with Purpose of Stay, Eating Habits, Allergies, and Accessibility Needs
2. **`accessibility-form.html`** - Detailed accessibility form with expandable sections
3. **`CheckInController_ADDITIONS.java`** - Controller methods to add to your existing CheckInController

## Steps to Implement

### Step 1: Copy HTML Templates
Copy the following files to your `src/main/resources/templates/` directory:
- `further-details.html`
- `accessibility-form.html`

### Step 2: Update CheckInController.java

Add the methods from `CheckInController_ADDITIONS.java` to your existing `CheckInController.java`:

1. **Add imports** (if not already present):
```java
import jakarta.servlet.http.HttpSession;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
```

2. **Add the following methods**:
   - `showFurtherDetails()` - GET `/checkin/further-details`
   - `submitFurtherDetails()` - POST `/checkin/further-details/submit`
   - `showAccessibilityForm()` - GET `/checkin/accessibility-form`
   - `submitAccessibilityForm()` - POST `/checkin/accessibility-form/submit`

3. **Modify your existing `submitCheckIn()` method** to redirect to further-details instead of confirmation:

```java
@PostMapping("/submit")
public String submitCheckIn(
        // ... your existing parameters ...
        HttpSession session,
        Model model) {
    
    // ... your existing code to save personal information ...
    
    // Save personal info to session for persistence
    Map<String, Object> personalInfoData = new java.util.HashMap<>();
    personalInfoData.put("guestFirstName", guestFirstName);
    personalInfoData.put("guestLastName", guestLastName);
    personalInfoData.put("guestEmail", guestEmail);
    personalInfoData.put("guestPhone", guestPhone);
    // ... add other personal info fields ...
    
    session.setAttribute("personalInfo_" + bookingId, personalInfoData);
    
    // Redirect to further-details page instead of confirmation
    return "redirect:/checkin/further-details?bookingReference=" + bookingReference + 
           "&bookingId=" + bookingId + "&guestEmail=" + guestEmail;
}
```

### Step 3: Update checkin-form.html

Update the form action in `checkin-form.html` to submit to `/checkin/submit`:

```html
<form id="checkinForm" th:action="@{/checkin/submit}" method="post">
    <!-- ... existing form fields ... -->
</form>
```

The form will automatically redirect to `further-details` after submission (handled by the controller).

### Step 4: Session Management

The implementation uses HTTP sessions to persist form data. Make sure your Spring Boot application has session management enabled (it should be enabled by default).

To configure session timeout in `application.properties`:
```properties
server.servlet.session.timeout=30m
```

### Step 5: Database Integration (Optional)

Currently, the data is stored in the session. To persist to the database:

1. Create or update the `pre_checkin_submissions` table in Supabase to include the new fields:
   - `purpose_of_stay`
   - `purpose_of_stay_other`
   - `dietary_preferences` (JSON array)
   - `dietary_preferences_other`
   - `has_allergies`
   - `allergies_details`
   - `accessibility_needs` (JSON array)
   - `accessibility_needs_other`
   - `accessibility_form_data` (JSON object with all accessibility form fields)

2. Update `SupabaseService.java` to add methods for saving further details and accessibility data.

3. Update the controller methods to save to the database instead of (or in addition to) the session.

## Features Implemented

### Further Details Page
- ✅ Purpose of Stay (Leisure, Religious, Business, Medical, Other)
- ✅ Eating Habits & Dietary Preferences (Vegetarian, Vegan, Halal, No Pork, Gluten-Free, Other)
- ✅ Allergies checkbox with details textarea
- ✅ Accessibility Needs (Wheelchair Access, Visual Assistance, Hearing Assistance, Other)
- ✅ Link to open full accessibility form
- ✅ Progress bar showing current step
- ✅ Back button to return to personal information
- ✅ Character counters for textareas
- ✅ Data persistence in session

### Accessibility Form
- ✅ Expandable accordion sections:
  - Room Features (accessibility basics, shower options, toilet grab bars, bed layout, alerts, convenience)
  - Communication & sensory (preferred channel, information format, sensory considerations, bedding)
  - Mobility/medical equipment (equipment bringing, services needed)
  - Service/assistance animal (traveling with animal, support needed)
  - Parking & arrival (parking needs, assistance & location)
  - Emergency & safety (alerts, additional notes)
- ✅ Opens in popup window
- ✅ Sends message to parent window on submit
- ✅ Data persistence in session
- ✅ Warning box about advance notice

## Navigation Flow

1. **Personal Information** (`/checkin/form`)
   - User fills personal details
   - Submits → Redirects to Further Details

2. **Further Details** (`/checkin/further-details`)
   - User selects preferences
   - Can click "Fill out full accessibility registration form" → Opens accessibility form in popup
   - Submits → Redirects to next step (EAT page - you'll need to create this)

3. **Accessibility Form** (`/checkin/accessibility-form`)
   - Opens in popup/modal window
   - User fills detailed accessibility requirements
   - Submits → Closes popup and refreshes parent page (Further Details)

## Data Persistence

All form data is stored in the HTTP session using keys:
- `personalInfo_{bookingId}` - Personal information data
- `furtherDetails_{bookingId}` - Further details data
- `accessibilityForm_{bookingId}` - Accessibility form data

When the user navigates back, the data is automatically loaded from the session and pre-filled in the forms.

## Testing

1. Start your Spring Boot application
2. Navigate to: `/checkin/form?booking=BK000039&email=test@example.com`
3. Fill in personal information and submit
4. You should be redirected to the Further Details page
5. Click "Fill out full accessibility registration form" link
6. The accessibility form should open in a popup
7. Fill in some data and submit
8. The popup should close and the Further Details page should refresh
9. Navigate back using the Back button
10. Your data should still be there

## Next Steps

1. Create the "EAT" page (step 3 in the progress bar)
2. Create the "Confirm information" page (step 4)
3. Create the "Accept & Sign" page (step 5)
4. Create the "Payment" page (step 6)
5. Integrate database persistence for all form data
6. Add validation and error handling
7. Add success messages after form submissions
