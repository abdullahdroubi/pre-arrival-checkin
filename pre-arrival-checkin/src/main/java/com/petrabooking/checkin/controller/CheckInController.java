package com.petrabooking.checkin.controller;

import jakarta.servlet.http.HttpSession;
import java.util.Arrays;
import java.util.Map;
import java.util.ArrayList;
import java.util.List;
import java.util.HashMap;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.petrabooking.checkin.model.Booking;
import com.petrabooking.checkin.model.Hotel;
import com.petrabooking.checkin.service.SupabaseService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
@RequestMapping("/checkin")
public class CheckInController {

    @Autowired
    private SupabaseService supabaseService;

    @GetMapping
    public String showHomePage(
            @RequestParam String booking,
            @RequestParam String email,
            Model model) {

        System.out.println("[CHECKIN] /checkin booking=" + booking + ", email=" + email);

        Booking bookingData = supabaseService.getBookingByReference(booking);
        if (bookingData == null) {
            model.addAttribute("error", "Booking not found. Please check your booking reference.");
            return "error";
        }

        if (bookingData.getGuestEmail() == null ||
                !bookingData.getGuestEmail().trim().equalsIgnoreCase(email.trim())) {
            model.addAttribute("error", "Email does not match this booking.");
            return "error";
        }

        if (bookingData.getHotelId() == null) {
            model.addAttribute("error", "Hotel ID is missing for this booking.");
            return "error";
        }

        Hotel hotel = supabaseService.getHotelById(bookingData.getHotelId());
        if (hotel == null) {
            model.addAttribute("error", "Hotel information not found.");
            return "error";
        }

        model.addAttribute("booking", bookingData);
        model.addAttribute("hotel", hotel);
        model.addAttribute("guestName",
                (bookingData.getGuestFirstName() == null ? "" : bookingData.getGuestFirstName()) + " " +
                        (bookingData.getGuestLastName() == null ? "" : bookingData.getGuestLastName()));
        model.addAttribute("guestEmail", email);

        String formattedRef = formatReservationNumber(bookingData.getBookingReference());
        model.addAttribute("formattedReservationNumber", formattedRef);

        return "home";
    }

    @GetMapping("/form")
    public String showCheckInForm(
            @RequestParam String booking,
            @RequestParam String email,
            Model model) {

        System.out.println("[CHECKIN] /checkin/form booking=" + booking + ", email=" + email);

        Booking bookingData = supabaseService.getBookingByReference(booking);
        if (bookingData == null) {
            model.addAttribute("error", "Booking not found. Please check your booking reference.");
            return "error";
        }

        if (bookingData.getGuestEmail() == null ||
                !bookingData.getGuestEmail().trim().equalsIgnoreCase(email.trim())) {
            model.addAttribute("error", "Email does not match this booking.");
            return "error";
        }

        if (bookingData.getHotelId() == null) {
            model.addAttribute("error", "Hotel ID is missing for this booking.");
            return "error";
        }

        Hotel hotel = supabaseService.getHotelById(bookingData.getHotelId());
        if (hotel == null) {
            model.addAttribute("error", "Hotel information not found.");
            return "error";
        }

        model.addAttribute("booking", bookingData);
        model.addAttribute("hotel", hotel);
        model.addAttribute("guestEmail", email);
        
        // Build guest name safely
        String guestName = "";
        if (bookingData.getGuestFirstName() != null) {
            guestName += bookingData.getGuestFirstName();
        }
        if (bookingData.getGuestLastName() != null) {
            if (!guestName.isEmpty()) guestName += " ";
            guestName += bookingData.getGuestLastName();
        }
        if (guestName.isEmpty()) {
            guestName = "Guest";
        }
        model.addAttribute("guestFullName", guestName);
        
        // Ensure numberOfGuests is not null
        Integer numberOfGuests = bookingData.getNumberOfGuests();
        if (numberOfGuests == null || numberOfGuests < 1) {
            numberOfGuests = 1;
        }
        model.addAttribute("numberOfGuests", numberOfGuests);

        return "checkin-form";
    }

    @GetMapping("/confirmation")
    public String showConfirmation(
            @RequestParam(value = "booking", required = false) String booking,
            @RequestParam(value = "bookingReference", required = false) String bookingReference,
            HttpSession session,
            Model model) {
        String resolvedBooking = (booking != null && !booking.isBlank()) ? booking : bookingReference;
        System.out.println("[CHECKIN] /checkin/confirmation booking=" + resolvedBooking);

        if (resolvedBooking == null || resolvedBooking.isBlank()) {
            model.addAttribute("error", "Missing reservation reference (booking).");
            return "error";
        }

        Booking bookingData = supabaseService.getBookingByReference(resolvedBooking);
        if (bookingData == null) {
            model.addAttribute("error", "Booking not found.");
            return "error";
        }

        if (bookingData.getHotelId() == null) {
            model.addAttribute("error", "Hotel ID is missing for this booking.");
            return "error";
        }

        Hotel hotel = supabaseService.getHotelById(bookingData.getHotelId());
        if (hotel == null) {
            model.addAttribute("error", "Hotel information not found.");
            return "error";
        }

        model.addAttribute("booking", bookingData);
        model.addAttribute("hotel", hotel);

        // Reservation number shown on the confirmation page
        try {
            model.addAttribute(
                    "formattedReservationNumber",
                    formatReservationNumber(bookingData.getBookingReference()));
        } catch (Exception ignored) {
            // Keep template rendering even if reference is not available
        }

        // Load "personal info" submitted in step 1-2 (stored in session by /checkin/submit)
        // and mask sensitive numeric fields (phone + id/passport).
        String bookingId = String.valueOf(bookingData.getId());
        Object personalInfoObj = session.getAttribute("personalInfo_" + bookingId);
        if (personalInfoObj instanceof Map) {
            Map<String, Object> personalInfo = (Map<String, Object>) personalInfoObj;

            String ownerFullName = buildGuestFullName(
                    (String) bookingData.getGuestFirstName(),
                    (String) bookingData.getGuestLastName());
            if (ownerFullName == null || ownerFullName.isBlank()) {
                ownerFullName = buildGuestFullName(
                        (String) personalInfo.get("guestFirstName"),
                        null);
            }
            model.addAttribute("ownerFullName", ownerFullName);

            String ownerPhone = stringOrEmpty(personalInfo.get("guestPhone"));
            String ownerIdPassport = stringOrEmpty(personalInfo.get("idPassportNumber"));
            model.addAttribute("ownerPhoneMasked", maskDigitsExceptLast4(ownerPhone));
            model.addAttribute("ownerIdPassportMasked", maskDigitsExceptLast4(ownerIdPassport));

            model.addAttribute("ownerEmail", stringOrEmpty(personalInfo.get("guestEmail")));
            model.addAttribute("ownerNationality", stringOrNull(personalInfo.get("nationality")));
            model.addAttribute("ownerDateOfBirth", stringOrNull(personalInfo.get("dateOfBirth")));

            // Other guests (stored as List<Map<String,String>> in submitCheckIn)
            Object additionalGuestsObj = personalInfo.get("additionalGuests");
            if (additionalGuestsObj instanceof List) {
                List<Map<String, Object>> maskedOtherGuests = new ArrayList<>();
                for (Object guestObj : (List<?>) additionalGuestsObj) {
                    if (!(guestObj instanceof Map)) continue;
                    Map<String, Object> guest = (Map<String, Object>) guestObj;

                    String fullName = stringOrEmpty(guest.get("full_name"));
                    String nationality = stringOrNull(guest.get("nationality"));
                    String dateOfBirth = stringOrNull(guest.get("date_of_birth"));
                    String idPassport = stringOrEmpty(guest.get("id_passport"));

                    Map<String, Object> v = new HashMap<>();
                    v.put("full_name", fullName);
                    v.put("nationality", nationality);
                    v.put("date_of_birth", dateOfBirth);
                    v.put("id_passport_masked", maskDigitsExceptLast4(idPassport));
                    maskedOtherGuests.add(v);
                }
                model.addAttribute("otherGuests", maskedOtherGuests);
            }
        }

        return "confirmation";
    }

    /**
     * Show further details page after personal information form
     */
    @GetMapping("/further-details")
    public String showFurtherDetails(
            @RequestParam String bookingReference,
            @RequestParam String bookingId,
            @RequestParam String guestEmail,
            HttpSession session,
            Model model) {

        System.out.println("[CHECKIN] /checkin/further-details bookingReference=" + bookingReference);

        // Load saved data from session if available
        Map<String, Object> savedData = (Map<String, Object>) session.getAttribute("furtherDetails_" + bookingId);
        if (savedData != null) {
            model.addAttribute("purposeOfStay", savedData.get("purposeOfStay"));
            model.addAttribute("purposeOfStayOther", savedData.get("purposeOfStayOther"));
            model.addAttribute("dietaryPreferences", savedData.get("dietaryPreferences"));
            model.addAttribute("dietaryPreferencesOther", savedData.get("dietaryPreferencesOther"));
            model.addAttribute("hasAllergies", savedData.get("hasAllergies"));
            model.addAttribute("allergiesDetails", savedData.get("allergiesDetails"));
            model.addAttribute("accessibilityNeeds", savedData.get("accessibilityNeeds"));
            model.addAttribute("accessibilityNeedsOther", savedData.get("accessibilityNeedsOther"));
        }

        // Load accessibility form data if available
        Map<String, Object> accessibilityData = (Map<String, Object>) session.getAttribute("accessibilityForm_" + bookingId);
        if (accessibilityData != null) {
            model.addAttribute("roomFeatures", accessibilityData.get("roomFeatures"));
            model.addAttribute("showerOption", accessibilityData.get("showerOption"));
            model.addAttribute("toiletGrabBars", accessibilityData.get("toiletGrabBars"));
            model.addAttribute("bedTransferSpace", accessibilityData.get("bedTransferSpace"));
            model.addAttribute("bedHeight", accessibilityData.get("bedHeight"));
            model.addAttribute("communicationPrefs", accessibilityData.get("communicationPrefs"));
            model.addAttribute("mobilityEquipment", accessibilityData.get("mobilityEquipment"));
            model.addAttribute("mobilityEquipmentOther", accessibilityData.get("mobilityEquipmentOther"));
            model.addAttribute("mobilityServices", accessibilityData.get("mobilityServices"));
            model.addAttribute("hasServiceAnimal", accessibilityData.get("hasServiceAnimal"));
            model.addAttribute("animalSupport", accessibilityData.get("animalSupport"));
            model.addAttribute("animalSupportOther", accessibilityData.get("animalSupportOther"));
            model.addAttribute("parkingNeeds", accessibilityData.get("parkingNeeds"));
            model.addAttribute("emergencyAlerts", accessibilityData.get("emergencyAlerts"));
            model.addAttribute("emergencyNotes", accessibilityData.get("emergencyNotes"));
        }

        model.addAttribute("bookingReference", bookingReference);
        model.addAttribute("bookingId", bookingId);
        model.addAttribute("guestEmail", guestEmail);

        return "further-details";
    }

    /**
     * Submit further details form
     */
    @PostMapping("/further-details/submit")
    public String submitFurtherDetails(
            @RequestParam String bookingReference,
            @RequestParam String bookingId,
            @RequestParam String guestEmail,
            @RequestParam(required = false) String purposeOfStay,
            @RequestParam(required = false) String purposeOfStayOther,
            @RequestParam(required = false) String[] dietaryPreferences,
            @RequestParam(required = false) String dietaryPreferencesOther,
            @RequestParam(required = false) String hasAllergies,
            @RequestParam(required = false) String allergiesDetails,
            @RequestParam(required = false) String[] accessibilityNeeds,
            @RequestParam(required = false) String accessibilityNeedsOther,
            HttpSession session,
            Model model) {

        System.out.println("[CHECKIN] Submitting further details for bookingId=" + bookingId);

        // Save to session for persistence
        Map<String, Object> data = new HashMap<>();
        data.put("purposeOfStay", purposeOfStay);
        data.put("purposeOfStayOther", purposeOfStayOther);
        data.put("dietaryPreferences", dietaryPreferences != null ? Arrays.asList(dietaryPreferences) : null);
        data.put("dietaryPreferencesOther", dietaryPreferencesOther);
        data.put("hasAllergies", "true".equals(hasAllergies));
        data.put("allergiesDetails", allergiesDetails);
        data.put("accessibilityNeeds", accessibilityNeeds != null ? Arrays.asList(accessibilityNeeds) : null);
        data.put("accessibilityNeedsOther", accessibilityNeedsOther);

        session.setAttribute("furtherDetails_" + bookingId, data);

        // TODO: Save to database (pre_checkin_submissions table)
        // For now, we'll just redirect to confirmation page
        // In a real implementation, you'd save this to Supabase

        // Redirect to EAT page (step 3)
        return "redirect:/checkin/eat?bookingReference=" + bookingReference +
               "&bookingId=" + bookingId + "&guestEmail=" + guestEmail;
    }

    /**
     * Show EAT (Estimated Arrival Time) step.
     */
    @GetMapping("/eat")
    public String showEAT(
            @RequestParam(value = "bookingReference", required = false) String bookingReference,
            @RequestParam(value = "booking", required = false) String booking,
            @RequestParam(value = "bookingId", required = false) String bookingIdStr,
            @RequestParam(value = "guestEmail", required = false) String guestEmail,
            HttpSession session,
            Model model) {
        String resolvedBookingReference =
                (bookingReference != null && !bookingReference.isBlank()) ? bookingReference : booking;

        if (resolvedBookingReference == null || resolvedBookingReference.isBlank()) {
            model.addAttribute("error", "Missing reservation reference (bookingReference).");
            return "error";
        }

        Booking bookingData = supabaseService.getBookingByReference(resolvedBookingReference);
        if (bookingData == null) {
            model.addAttribute("error", "Booking not found.");
            return "error";
        }

        int bookingId = bookingData.getId();
        String resolvedGuestEmail = (guestEmail != null && !guestEmail.isBlank())
                ? guestEmail
                : bookingData.getGuestEmail();

        model.addAttribute("bookingReference", resolvedBookingReference);
        model.addAttribute("bookingId", bookingId);
        model.addAttribute("guestEmail", resolvedGuestEmail);

        // Pre-fill estimated arrival time if user already submitted
        Object eatObj = session.getAttribute("eat_" + bookingId);
        if (eatObj instanceof String) {
            model.addAttribute("estimatedArrivalTime", eatObj);
        }

        return "eat";
    }

    /**
     * Submit EAT and redirect to confirmation.
     */
    @PostMapping("/eat/submit")
    public String submitEAT(
            @RequestParam Map<String, String> formData,
            HttpSession session,
            Model model) {
        // Use only raw formData to avoid Spring request parameter binding issues.
        String bookingReference = formData.get("bookingReference");
        if (bookingReference == null || bookingReference.isBlank()) {
            bookingReference = formData.get("booking");
        }

        if (bookingReference == null || bookingReference.isBlank()) {
            // Keep consistent with confirmation: show a normal error page instead of 400
            model.addAttribute("error", "Missing reservation reference (bookingReference).");
            return "error";
        }

        Booking bookingData = supabaseService.getBookingByReference(bookingReference);
        if (bookingData == null) {
            model.addAttribute("error", "Booking not found.");
            return "error";
        }

        int bookingId = bookingData.getId();

        // Be resilient to different field names used by templates
        String resolvedEstimatedArrivalTime = formData.get("estimatedArrivalTime");
        if (resolvedEstimatedArrivalTime == null || resolvedEstimatedArrivalTime.isBlank()) {
            resolvedEstimatedArrivalTime = formData.get("eatTime");
        }
        if (resolvedEstimatedArrivalTime == null || resolvedEstimatedArrivalTime.isBlank()) {
            resolvedEstimatedArrivalTime = formData.get("estimatedArrival");
        }

        if (resolvedEstimatedArrivalTime != null && !resolvedEstimatedArrivalTime.isBlank()) {
            session.setAttribute("eat_" + bookingId, resolvedEstimatedArrivalTime);
        }

        return "redirect:/checkin/confirmation?bookingReference=" + bookingReference +
               "&booking=" + bookingReference;
    }

    /**
     * Show accessibility form (opens in popup/modal)
     */
    @GetMapping("/accessibility-form")
    public String showAccessibilityForm(
            @RequestParam String bookingReference,
            @RequestParam String bookingId,
            @RequestParam String guestEmail,
            HttpSession session,
            Model model) {

        System.out.println("[CHECKIN] /checkin/accessibility-form bookingId=" + bookingId);

        // Load saved data from session if available
        Map<String, Object> savedData = (Map<String, Object>) session.getAttribute("accessibilityForm_" + bookingId);
        if (savedData != null) {
            model.addAttribute("roomFeatures", savedData.get("roomFeatures"));
            model.addAttribute("showerOption", savedData.get("showerOption"));
            model.addAttribute("toiletGrabBars", savedData.get("toiletGrabBars"));
            model.addAttribute("bedTransferSpace", savedData.get("bedTransferSpace"));
            model.addAttribute("bedHeight", savedData.get("bedHeight"));
            model.addAttribute("communicationPrefs", savedData.get("communicationPrefs"));
            model.addAttribute("mobilityEquipment", savedData.get("mobilityEquipment"));
            model.addAttribute("mobilityEquipmentOther", savedData.get("mobilityEquipmentOther"));
            model.addAttribute("mobilityServices", savedData.get("mobilityServices"));
            model.addAttribute("hasServiceAnimal", savedData.get("hasServiceAnimal"));
            model.addAttribute("animalSupport", savedData.get("animalSupport"));
            model.addAttribute("animalSupportOther", savedData.get("animalSupportOther"));
            model.addAttribute("parkingNeeds", savedData.get("parkingNeeds"));
            model.addAttribute("emergencyAlerts", savedData.get("emergencyAlerts"));
            model.addAttribute("emergencyNotes", savedData.get("emergencyNotes"));
        }

        model.addAttribute("bookingReference", bookingReference);
        model.addAttribute("bookingId", bookingId);
        model.addAttribute("guestEmail", guestEmail);

        return "accessibility-form";
    }

    /**
     * Submit accessibility form
     */
    @PostMapping("/accessibility-form/submit")
    @ResponseBody
    public Map<String, String> submitAccessibilityForm(
            @RequestParam String bookingReference,
            @RequestParam String bookingId,
            @RequestParam String guestEmail,
            @RequestParam(required = false) String[] roomFeatures,
            @RequestParam(required = false) String showerOption,
            @RequestParam(required = false) String toiletGrabBars,
            @RequestParam(required = false) String bedTransferSpace,
            @RequestParam(required = false) String bedHeight,
            @RequestParam(required = false) String[] communicationPrefs,
            @RequestParam(required = false) String[] mobilityEquipment,
            @RequestParam(required = false) String mobilityEquipmentOther,
            @RequestParam(required = false) String[] mobilityServices,
            @RequestParam(required = false) String hasServiceAnimal,
            @RequestParam(required = false) String[] animalSupport,
            @RequestParam(required = false) String animalSupportOther,
            @RequestParam(required = false) String[] parkingNeeds,
            @RequestParam(required = false) String[] emergencyAlerts,
            @RequestParam(required = false) String emergencyNotes,
            HttpSession session) {

        System.out.println("[CHECKIN] Submitting accessibility form for bookingId=" + bookingId);

        // Save to session for persistence
        Map<String, Object> data = new HashMap<>();
        data.put("roomFeatures", roomFeatures != null ? Arrays.asList(roomFeatures) : null);
        data.put("showerOption", showerOption);
        data.put("toiletGrabBars", toiletGrabBars);
        data.put("bedTransferSpace", bedTransferSpace);
        data.put("bedHeight", bedHeight);
        data.put("communicationPrefs", communicationPrefs != null ? Arrays.asList(communicationPrefs) : null);
        data.put("mobilityEquipment", mobilityEquipment != null ? Arrays.asList(mobilityEquipment) : null);
        data.put("mobilityEquipmentOther", mobilityEquipmentOther);
        data.put("mobilityServices", mobilityServices != null ? Arrays.asList(mobilityServices) : null);
        data.put("hasServiceAnimal", "true".equals(hasServiceAnimal));
        data.put("animalSupport", animalSupport != null ? Arrays.asList(animalSupport) : null);
        data.put("animalSupportOther", animalSupportOther);
        data.put("parkingNeeds", parkingNeeds != null ? Arrays.asList(parkingNeeds) : null);
        data.put("emergencyAlerts", emergencyAlerts != null ? Arrays.asList(emergencyAlerts) : null);
        data.put("emergencyNotes", emergencyNotes);

        session.setAttribute("accessibilityForm_" + bookingId, data);

        // TODO: Save to database (pre_checkin_submissions table)
        // For now, we'll just return success
        // In a real implementation, you'd save this to Supabase

        Map<String, String> response = new HashMap<>();
        response.put("status", "success");
        response.put("message", "Accessibility form submitted successfully");

        return response;
    }

    @PostMapping("/submit")
    public String submitCheckIn(
            @RequestParam Map<String, String> formData,
            HttpSession session,
            Model model) {
        System.out.println("[CHECKIN] /checkin/submit - Processing check-in submission");

        // Get booking info
        String bookingRef = formData.get("bookingReference");
        Booking bookingData = supabaseService.getBookingByReference(bookingRef);

        if (bookingData == null) {
            model.addAttribute("error", "Booking not found.");
            return "error";
        }

        String bookingId = String.valueOf(bookingData.getId());
        String guestEmail = formData.get("guestEmail");

        // Count guests from form
        int submittedGuests = 1; // Primary guest
        for (String key : formData.keySet()) {
            if (key.startsWith("guest_") && key.contains("_fullName")) {
                submittedGuests++;
            }
        }

        // Prepare check-in data
        Map<String, Object> checkInData = new HashMap<>();

        // Primary guest data
        checkInData.put("booking_id", bookingData.getId());
        checkInData.put("hotel_id", bookingData.getHotelId());
        checkInData.put("guest_full_name", formData.get("guestFirstName"));
        checkInData.put("guest_email", formData.get("guestEmail"));
        checkInData.put("guest_phone", formData.get("countryCode") + " " + formData.get("guestPhone"));
        checkInData.put("id_passport_number", formData.get("idPassportNumber"));
        checkInData.put("nationality", formData.get("nationality"));
        checkInData.put("date_of_birth", formData.get("dateOfBirth"));
        checkInData.put("iqama_number", formData.get("iqamaNumber"));
        checkInData.put("submitted_guests_count", submittedGuests);
        checkInData.put("booked_guests_count", bookingData.getNumberOfGuests());
        checkInData.put("requires_additional_payment", submittedGuests > bookingData.getNumberOfGuests());
        checkInData.put("submitted_at", java.time.LocalDateTime.now().toString());

        // Additional guests data (store as JSON array)
        List<Map<String, String>> additionalGuests = new ArrayList<>();
        for (int i = 2; i <= submittedGuests; i++) {
            Map<String, String> guest = new HashMap<>();
            
            // Required fields
            guest.put("full_name", formData.get("guest_" + i + "_fullName"));
            guest.put("id_passport", formData.get("guest_" + i + "_idPassport"));
            guest.put("nationality", formData.get("guest_" + i + "_nationality"));
            guest.put("date_of_birth", formData.get("guest_" + i + "_dateOfBirth"));
            
            // Optional email - only add if provided
            String email = formData.get("guest_" + i + "_email");
            if (email != null && !email.trim().isEmpty()) {
                guest.put("email", email.trim());
            }
            
            // Optional phone - only add if provided
            String phone = formData.get("guest_" + i + "_phone");
            String countryCode = formData.get("guest_" + i + "_countryCode");
            if (phone != null && !phone.trim().isEmpty() && countryCode != null) {
                guest.put("phone", countryCode + " " + phone.trim());
            }
            
            // Optional iqama - only add if provided
            String iqama = formData.get("guest_" + i + "_iqama");
            if (iqama != null && !iqama.trim().isEmpty()) {
                guest.put("iqama", iqama.trim());
            }
            
            additionalGuests.add(guest);
        }

        if (!additionalGuests.isEmpty()) {
            // Convert to JSON string using Jackson ObjectMapper
            try {
                ObjectMapper mapper = new ObjectMapper();
                checkInData.put("additional_guests", mapper.writeValueAsString(additionalGuests));
            } catch (Exception e) {
                System.out.println("[CHECKIN] Error serializing additional guests: " + e.getMessage());
            }
        }

        // Save personal info to session for persistence
        Map<String, Object> personalInfoData = new HashMap<>();
        personalInfoData.put("guestFirstName", formData.get("guestFirstName"));
        personalInfoData.put("guestEmail", formData.get("guestEmail"));
        personalInfoData.put("guestPhone", formData.get("countryCode") + " " + formData.get("guestPhone"));
        personalInfoData.put("idPassportNumber", formData.get("idPassportNumber"));
        personalInfoData.put("nationality", formData.get("nationality"));
        personalInfoData.put("dateOfBirth", formData.get("dateOfBirth"));
        personalInfoData.put("iqamaNumber", formData.get("iqamaNumber"));
        personalInfoData.put("additionalGuests", additionalGuests);
        session.setAttribute("personalInfo_" + bookingId, personalInfoData);

        // Submit to Supabase
        try {
            supabaseService.submitCheckIn(checkInData);
            System.out.println("[CHECKIN] Check-in submitted successfully");

            // Redirect to further-details page instead of confirmation
            return "redirect:/checkin/further-details?bookingReference=" + bookingRef + 
                   "&bookingId=" + bookingId + "&guestEmail=" + guestEmail;
        } catch (Exception e) {
            System.out.println("[CHECKIN] Error submitting check-in: " + e.getMessage());
            model.addAttribute("error", "Failed to submit check-in. Please try again.");
            return "error";
        }
    }

    private String formatReservationNumber(String bookingRef) {
        if (bookingRef == null || bookingRef.isBlank()) {
            return "#N/A";
        }
        String numbers = bookingRef.replaceAll("[^0-9]", "");
        if (numbers.length() >= 4) {
            return "#" + numbers.substring(0, 4) + "-" + numbers.substring(4);
        }
        return "#" + bookingRef;
    }

    private String buildGuestFullName(String firstName, String lastName) {
        String f = stringOrEmpty(firstName).trim();
        String l = stringOrEmpty(lastName).trim();
        if (f.isEmpty() && l.isEmpty()) return "Guest";
        return (f + " " + l).trim();
    }

    private String stringOrEmpty(Object v) {
        return v == null ? "" : String.valueOf(v);
    }

    private String stringOrNull(Object v) {
        if (v == null) return null;
        String s = String.valueOf(v).trim();
        return s.isEmpty() ? null : s;
    }

    /**
     * Mask all digits except the last 4 digits, while preserving the original separators.
     * Example: "+966 501 234 5678" -> "+*** 501 234 5678" (digit-level masking).
     */
    private String maskDigitsExceptLast4(String input) {
        if (input == null) return "";

        String digitsOnly = input.replaceAll("\\D", "");
        if (digitsOnly.isEmpty()) return input;

        if (digitsOnly.length() <= 4) {
            // If it's already 4 or fewer digits, don't mask anything.
            return input;
        }

        int digitsToMaskCount = digitsOnly.length() - 4;
        String last4 = digitsOnly.substring(digitsOnly.length() - 4);
        StringBuilder maskedDigits = new StringBuilder();
        for (int i = 0; i < digitsToMaskCount; i++) {
            maskedDigits.append('*');
        }
        maskedDigits.append(last4);

        // Rebuild the output preserving separators.
        int digitIndex = 0;
        StringBuilder out = new StringBuilder();
        for (int i = 0; i < input.length(); i++) {
            char c = input.charAt(i);
            if (Character.isDigit(c)) {
                out.append(maskedDigits.charAt(digitIndex));
                digitIndex++;
            } else {
                out.append(c);
            }
        }

        return out.toString();
    }
}
